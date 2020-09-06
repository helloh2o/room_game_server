local socket = require "socket"
print("classic_ddz lua module is loaded", socket.gettime())

local protobuf = require "protobuf"

require("opcode_common")

local luapath = '/root/golang/src/server/lua/game/classic_ddz/'
if DEBUG then
    print('reload proto')
    local addr = io.open(luapath .. "protocol/gameserver.pb", "rb")
    local buffer = addr:read "*a"
    addr:close()
    protobuf.register(buffer)
else
    --if not STARTED then
    local addr = io.open(luapath .. "protocol/gameserver.pb", "rb")
    local buffer = addr:read "*a"
    addr:close()
    protobuf.register(buffer)
    --end
end

local pokers_module = require('pokers')
local protocol 		= require('protocol')
local place_module  = require('place')
local cjson_safe    = require('cjson.safe') 

local none = "none"
 
local auto_action_mingpai_time  = 5
local auto_action_qdz_time      = 10
local auto_action_jiabei_time   = 10
local auto_ready_chupai_time    = 30

local game_player_count = 3
 
local room_not_gaming            = 1
local room_sendpokers            = 2
local room_qiangdizhu            = 3
local room_jiabei            	 = 4
local room_gaming                = 5
local room_game_over             = 6

local room_timer = {
    [protocol.game_action_mingpai] = {id = protocol.game_action_mingpai, time = 10},
    [protocol.game_action_qdz] = {id = protocol.game_action_qdz, time = 10},
    [protocol.game_action_jiabei] = {id = protocol.game_action_jiabei, time = 10},
    [protocol.game_action_chupai] = {id = protocol.game_action_chupai, time = 10},
}

global_players = global_players or {}
global_rooms = global_rooms or {}

if public_jdddz_room_tree == nil then
    public_jdddz_room_tree = {}
    for k, v in pairs(place_module.place_config) do
        if v.idtype == 'custom' then
            public_jdddz_room_tree[k] = {free = {}, assigned={[0] = {}, [1]={}, [2]={}, [3] = {}}}
        else
            public_jdddz_room_tree[k] = {[0] = {}, [1]={}, [2]={}, [3] = {}}
        end
    end
end

--构建一个玩家数据
function get_player(dbdata, _pid)
    local player = {
        pid = _pid,
        online = true,
        room = nil,
        seat = nil,
        seat_index = 0,
 
        reset = function (self) 
            self.room = nil
            self.seat = nil
            self.seat_index = 0
        end
    }
 
    for k, v in pairs(dbdata) do
        player[k] = v
    end
 
    player.oid_str = tostring(player.oid)
    if player.tag == 911 then
        player.super = true
    end
 
    local test, geo = pcall(function()
        local geo = std_string.split(ip2_module.IpLocation(player.peer_host), '\t')
        if #geo >= 3 then
            table.remove(geo, 1)
        end
 
        geo = table.concat(geo)
 
        return geo
    end)
    player['peer_geo'] = test and geo or '火星'
    
    return player
end

function get_ddz_room(_pid, _roomid)
    local room = {
        roomid = _roomid,
        pid = _pid,
        status = room_not_gaming,

        --for custom
        ju_count = 0,  --房间进行的局数
        ju_infos = {},

        dismiss_apply = false,

        seats = {none, none, none},
        play_seats = {},  

        --place_config = place_config,
        place_id = 'jdddz_custom', --place_config.id,
        place_type = 'custom', --place_config.idtype,
        --gametype = gametype,
        --game_config = game_config,

        banker_seat = 0, 
        dizhu_seat = 0,
        curr_turn = 0,
        next_turn = 0,

        poker = nil,
        old_seqs = {},
        dizhu_pokers = {}, --三张地主牌
        player_count = 0,
        passwd = none,
 
        --public wating action
        --可能有多个玩家，多个action
        waiting_actions = nil, 

	    game_log = {room_info={}, player_infos={}, players={}, log={}},
    }

    return room
end

function get_ddz_match_room(_pid, _roomid, _gametype, config)
    local room = {
        match_players = {},
        match_player_pids = {},
        match_player_110 = {},
        is_match_room=true,
        pid=_pid,
        gametype=_gametype,
        place_id=config.id,
        place_type=config.idtype,
        place_config = config,
        roomid = _roomid,
        passwd = none,
    }

    return room
end

function get_room_info(roomid)
    local room = global_rooms[roomid]

    return {
            ju_count     = room.ju_count, 
            creater_id   = room.creater_id,
            creater_type = room.creater_type,
            passwd       = room.passwd
        }

end

function get_public_room_pid(place)
    for i=0, 3 do
        for k, v in pairs(public_jdddz_room_tree[place][3-i]) do
            return v.roomid, v.pid
        end
    end
end


function force_change_public_room_tree(player_count, roomid)
    print("room change count", roomid)
    local room = global_rooms[roomid]
    if room == nil then
        return
    end

    for k, v in pairs(public_jdddz_room_tree[room.place_id]) do
        v[roomid] = nil
    end

    public_jdddz_room_tree[room.place_id][player_count] = public_jdddz_room_tree[room.place_id][player_count] or {}

    public_jdddz_room_tree[room.place_id][player_count][roomid] = room

    return player_count   
end

function change_public_room_tree(roomid)
    print("room change count", roomid)
    local room = global_rooms[roomid]
    if room == nil then
        return
    end

    if is_custom(room) then
        for k, v in pairs(public_jdddz_room_tree[room.place_id]['assigned']) do
            if v[roomid] then
                v[roomid] = nil
                break
            end
        end   
       
        local player_count = 0
        for i, v in ipairs(room.seats) do
            if v ~= none then
                player_count = player_count + 1
            end
        end

        if DEBUG then print("player_count:", player_count, type) end

        public_jdddz_room_tree[room.place_id]['assigned'][player_count][roomid] = room

        return player_count   
    else
        for k, v in pairs(public_jdddz_room_tree[room.place_id]) do
            v[roomid] = nil
        end

        local player_count = 0
        for i, v in ipairs(room.seats) do
            if v ~= none then
                player_count = player_count + 1
            end
        end

        if DEBUG then print("player_count:", player_count) end

        public_jdddz_room_tree[room.place_id][player_count][roomid] = room

        return player_count   
    end
end

function room_terminate(roomid)
    if DEBUG then print("jdddz_room terminate") end
    local room = global_rooms[roomid]

    if (room == nil) then
	    return
    end

    --global_next[room.pid] = nil

    global_rooms[roomid] = nil

    for k, v in pairs(public_jdddz_room_tree[room.place_id])  do
        v[roomid] = nil
    end
end

function is_match_place(place_id)
    return place_id:sub(-5) == 'match'
end

function is_custom(room)
    return room.place_type == 'custom'
end

function room_init(pid, roomid)
    local room = get_ddz_room(pid, roomid)
    local place_id = 'jdddz_custom'
    global_rooms[roomid] = room
    public_jdddz_room_tree[place_id]['free'][roomid] = room
end

function player_init(pid, dbdata, place) 
    --add_server_info_player_count(place, 1)
    local data_table = cjson_safe.decode(dbdata)
    if DEBUG then print(tostring(data_table.oid) .. " init") end
    global_players[data_table.oid] = get_player(data_table, pid)
    
    return true
end
 
function player_terminate(place, oid)
    --[[local player = global_players[oid]
 
    if player ~= nil then
        global_next[player.pid] = nil
    end]]
 
    --add_server_info_player_count(place, -1)
 
    global_players[oid] = nil
end

--每一局逻辑需要重置的数据
function reset_room(self)
    assert(self ~= nil)
    self.status = room_not_gaming 
     
    self.dismiss_apply = false
 
    self.waiting_actions = nil
 
    self.can_call_other = true
    self.play_seats = {}
    self.seats = {none, none, none}

    --self.operate_seat = nil
 
    self.curr_turn = 0
    self.dizhu_seat = 0
    self.banker_seat = 0
    self.poker = nil
    self.old_seqs = {}
 
    self.game_log = {log = {}, begin_time = 0}
end
 
--每一局重启
function restart_room(self)
    assert(self ~= nil)
    reset_room(self) 
    -- only restart
    for i, v in ipairs(self.seats) do
        if v ~= none then
            v.auto_count = 0
        
            v.dismiss_seq=nil
            v.dismiss = 0 
            v.ready_seq = nil
 
            v.action_seq = nil
            v.action_bin = nil
 
            v.hand_seq 	= {}
         
            v.ingame=false
            v.inroom=true
            v.last_chu = {}

            v.qdz   = -1 
            v.jiabei     = -1
            v.mingpai = -1
        end
    end
end

global_packet_handlers = {}
global_game_action_handlers = {}
global_game_timeout_handlers = {}

function register_packet_handler()
    --global_packet_handlers["cs_player_enter_room"]  = on_cs_player_enter_room
    global_packet_handlers["cs_game_action"]        = on_cs_game_action
    global_packet_handlers["cs_player_leave_room"]  = on_cs_player_leave_room
    global_packet_handlers["cs_ready_game"]         = on_cs_ready_game
    global_packet_handlers["cs_change_online"]      = on_cs_change_online
    global_packet_handlers["cs_leave_room"]         = on_cs_leave_room 
    global_packet_handlers["cs_add_bot"]	        = on_cs_add_bot
    global_packet_handlers['cs_game_debug_time']    = on_cs_game_debug_time
    global_packet_handlers["cs_dismiss_room"]       = on_cs_dismiss_room
    global_packet_handlers["cs_game_auto"]          = on_cs_game_auto
    global_packet_handlers["cs_gift_action"]        = on_cs_gift_action
end

function register_game_action_handler()
    global_game_action_handlers[protocol.game_action_mingpai]   = on_game_action_mingpai  --无顺序
    global_game_action_handlers[protocol.game_action_qdz]       = on_game_action_qdz
    global_game_action_handlers[protocol.game_action_jiabei]    = on_game_action_jiabei --无顺序
    global_game_action_handlers[protocol.game_action_chupai]    = on_game_action_chupai
end

function register_game_timeout_handler()
    global_game_timeout_handlers[protocol.game_action_mingpai]  = on_game_timeout_mingpai
    global_game_timeout_handlers[protocol.game_action_qdz]      = on_game_timeout_qdz
    global_game_timeout_handlers[protocol.game_action_jiabei]   = on_game_timeout_jiabei
    global_game_timeout_handlers[protocol.game_action_chupai]   = on_game_timeout_chupai
end

--function player_on_packet(oid, packet_bin, roomid)
function onmessage(oid, packet_bin)
	local player = global_players[oid]
	if (player == nil) then
print("onmessage player is nil")
		return
    end
    
    local room = player.room
    if room == nil then
print("onmessage room is nil")
		return
	end

	--[[if room.roomid ~= roomid then
		local Return = {}
		return Return
    end]]
    
	--unpack packet
	local protocol_id, protocol_content = 
	protocol.game_protocol_unpack_bin(packet_bin)

	if (not protocol_id) or (not protocol_content) then
print("onmessage, packet bin unpack error.")
		local Return = {}
		--add_error_log(Return, msg or 'error_proto')
		return Return
    end
    
	if protocol_id == 'heartbeat' then
        local Return = {}
	    --add_send_bin(Return, player.pid, packet_bin)	
        return Return
    end 

    if is_custom(room) then
        if room.dismiss then
            if DEBUG then print('room is already dismiss') end
            return
        end
    end

	local handler = global_packet_handlers[protocol_id]

	if room.is_match_room then
		--在匹配房间中，只有三个协议
		if protocol_id ~= 'cs_leave_room' and
			protocol_id ~= 'cs_match_game' and
			protocol_id ~= 'cs_add_bot'
			then
				--if DEBUG then print('应该是正常的包:', protocol_id) end
				return
		else
			if protocol_id == 'cs_match_game' then
				--if DEBUG then print('应该是匹配的包:', protocol_id) end
				return
			end
		end
    end
		--if DEBUG then print('--------------------------protocol_id:'..tostring(protocol_id)) end

        if DEBUG then print(protocol_id) end
	if handler ~= nil then
		return handler(player, protocol_content)
	else
        if DEBUG then print(protocol_id) end
		return return_unhandle_when_debug(player.pid) 
	end
end

--踢到玩家的方法
function make_player_leave(oid, why)
    local player = global_players[oid]
    if player == nil then return end
    local room = player.room
    local seat = player.seat

    if (room == nil or seat == nil) then
        return
    end

    if (seat.ingame) then
        return
    end

    seat.ingame = false
    seat.inroom = false

    if room.player_count > 0 then room.player_count = room.player_count - 1 end

    --[[if not not_send_leave then
        add_send(Return, player.pid, pack_protocol("sc_leave_room",
        {
            result = 0,
            reason = protocol.error_id_and_desc[why],
        })
        )
    end

    broadcast_packet_except(Return, room.seats, pack_protocol("sc_leave_room_notify",
    {
        seat_index = seat.index,
    }),
    player.pid)]]

    room.seats[seat.index] = none
    player:reset()

    --没有玩家的时候就把状态设置为room_not_gaming
    if player_count == 0 then
        room.status = room_not_gaming
        room.game_over_uuid = nil
    end
end

function helper_game_start(room, Return)
    local now = os.time() 
    for i, v in ipairs(room.seats) do
        if v ~= none then
            v.point = v.point or 0
	        v.ingame=true

            table.insert(room.play_seats, v)
        end
    end

    assert(game_player_count == #room.play_seats)
    
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    room.poker = pokers_module.normal_shuffle_tiles()

    room.log_uid = getUUID()
    --清空上一场日志
	room.game_log.begin_time       = now    --开始时间

    if room.game_log.log == nil then
        room.game_log.log = {} --详细游戏日志
    end

    room.old_seqs = {}
    room.waiting_actions = {}

    -- rand first operate player
    room.status = room_sendpokers

    for i, v in ipairs(room.seats) do
        assert(v ~= nil)
        for i=1, 17 do
            table.insert(v.hand_seq, pokers_module.deal_poker(room.poker))
        end

        room.waiting_actions[i] = {action_id = protocol.game_action_mingpai}
    end
    for i=1, 3 do
        table.insert(room.dizhu_pokers, pokers_module.deal_poker(room.poker))
    end

    for i, v in ipairs(room.seats) do
        add_send(Return, v.player.pid, pack_protocol(
                     "sc_start_game", 
                     {
                        other_infoes = pokers_module.notify_other_hand_seq(room, i, 17),
                        you_seq_info = {seat_index = i, ['hand_seq'] = v.hand_seq},
                        --tiles_remain	= #room.remain,
                        banker_seat = room.banker_seat
                     }))
    end
end

function player_enter_room(oid)
    print("player enter room, ", oid)
    local player = global_players[oid]
    local room = nil --global_rooms[roomid]
    local room_id = 0
    for i, v in pairs(global_rooms) do 
        if v.player_count < 3 then
            room = v
            room_id = i
            break
        end
    end

    if player == nil or room == nil then 
        print("player enter room faild.", oid)
        return room_id
    end
print("----------------------enter_room,", room_id, ",", room.player_count)
    local Return = {}
    local new_player = true
    for i, v in ipairs(room.seats) do
        if v ~= none and v.player.oid == oid then
            new_player = false
        end
    end

    local enter_room_succ = false
    if (room.status == room_not_gaming) then
        for i = 1, #room.seats do
            if room.seats[i] == none then  
                room.seats[i] = { index = i, 
                    ['player'] = player,                
                    dismiss_seq = nil,
                    dismiss     = 0,
                    ready_seq   = nil,
                    action_seq  = nil,
                    action_bin  = nil,
               
                    ready=false,
                
                    hand_seq= {},
                    last_chu = {},
              
                    ingame = false,
                    inroom = true,
                
                    mingpai = -1,
                    jiabei = -1,
                    qdz = -1
                }

                player.seat = room.seats[i]
                player.seat_index = i
                player.room = room	
 
                enter_room_succ = true
                break
            end
        end
    else
        if new_player == false then
            enter_room_succ = true
            print("player continue game, ", player.id)
        end
    end

    if enter_room_succ == false then
        print("player enter room faild, ", player.id)
        return room_id
    end

    local _seat_infoes = {}
    for i, v in ipairs(room.seats) do
        if v ~= none then
            if (v.player.oid == player.oid) then
                table.insert(_seat_infoes, 
                           {		
                              seat_index  = i,
                              player_info = {
                                 oid 		= player.oid, 
                                 id       = player.id,
                                 idtype   = player.idtype,
                                 nick_name= player.nick_name,
                                 gold		= player.gold,
                                 sex		= player.sex,
                                 portrait = player.portrait,
                                 ip       = player.peer_host,
                                 exp      = player.exp,
                                 online   = player.online,
                                 signature = player.signature
                              },
                              ready       = v.ready,
                              hand_seq    = v.hand_seq,
                              last_chu    = v.last_chu,
                              money       = v.point,
                           })
            else
                table.insert(_seat_infoes, 
                           {		
                              seat_index  = i,
                              player_info = {
                                 oid      = player.oid,
                                 id       = player.id,
                                 idtype   = player.idtype,
                                 nick_name= player.nick_name,
                                 gold		= player.gold,
                                 sex		= player.sex,
                                 portrait = player.portrait,
                                 ip       = player.peer_host,
                                 exp      = player.exp,
                                 online   = player.online,
                                 signature = player.signature
                              },
                              ready       = v.ready,
                              hand_seq    = {}, --mahjong.notify_hand_seq(v.hand_seq, player.super),
                              last_chu    = v.last_chu,
                              money       = v.point
                           })
  
            end
        end 
    end

    add_send(Return, player.pid, pack_protocol(
                  "sc_enter_room",
                  {seat_index	 = player.seat_index,
                   --seat_infoes   = _seat_infoes,
                   --roomid		 = room.roomid,
                   --room_pwd      = room.passwd,
                   --room_base     = room.place_config.base_zhu,
                   --game_config   = encode_json(room.game_config),
                   --place = room.place_id,
                   --gametype = room.gametype,
                   --current_round = room.ju_count+1,
                   --owner_seat = room.owner and room.owner.seat_index or 0,
                   --creater_id = room.creater_id,
                   --creater_type = room.creater_type
                  }))


    --room.player_count = room.player_count + 1
    room.player_count = change_public_room_tree(room.roomid)

    return room_id, pack_return(Return)
end


function on_cs_player_leave_room(player, packet)
    

end

function on_cs_ready_game(player, packet)
    local seat = player.seat
    local room = player.room
    if seat == nil or seat.ready then 
        return 
    end

    if room == nil or room.status ~= room_not_gaming then
        return
    end

    local all_ready = true
    for i, v in ipairs(room.seats) do
        if v == none or v.ready == false then
            all_ready = false
            break
        end
    end

    local Return = {}
    add_send(Return, player.pid, pack_protocol(
                   "sc_ready_game"))

    broadcast_packet_except(Return,
                   room.seats,
                   pack_protocol("sc_ready_game_notify",
                                 {seat_index = player.seat_index}),
                   player.pid
                  )

    if all_ready then
        helper_game_start(room, Return)
    end

    return pack_return(Return)
end

function on_cs_change_online(player, packet)

end

function on_cs_leave_room(player, packet)
    
    
end

function on_cs_game_action(player, packet)
    local room = player.room  
    local _action_id = content_lua.id

    local handler = nil
    --[[if (room.status == room_sendpokers or room.status == room_jiabei) then
        handler = global_game_action_handlers[_action_id]
        if handler ~= nil then
            return handler(player, content_lua)
        end
    end]]

    if room.waiting_actions == nil or room.waiting_actions[player.seat_index] == nil or room.waiting_actions[player.seat_index].action_id ~= _action_id then 
        return
    end
    
    handler = global_game_action_handlers[_action_id]

    if handler ~= nil then
       return handler(player, content_lua)
    else
       --return return_unhandle_when_debug(player.pid)
    end
end

function on_game_action_mingpai(player, packet)
    local room = player.room
    if room.status ~= room_sendpokers then return end

    player.seat.mingpai = packet.action
    room.waiting_actions[player.seat_index] = nil

    local all_sure = true
    for i, v in ipairs(room.seats) do
        if (v.mingpai == -1) then 
            all_sure = false
            break
        end
    end

    local Return = {}
    if packet.action == 1 then --明牌
        local content = {seat_index = player.seat_index, action_id = protocol.game_action_mingpai, pokers = player.seat.hand_seq}
        local packet_bin = pack_protocol("sc_game_action", content)
        broadcast_packet(Return, room, packet_bin)
    end

    if (all_sure == true) then
        helper_game_start_qdz(Return, room)
    end

    return Return
end

function helper_game_start_qdz(Return, room)
    if (room.status ~= room_qiangdizhu) then
        room.status = room_qiangdizhu
        local packet_bin = pack_protocol("sc_game_change_status", {room_status = room_qiangdizhu})
        broadcast_packet(Return, room, packet_bin)
    end
    room.curr_turn = random(#room.play_seats)
    set_turn_waiting_action(room, protocol.game_action_qdz)

    add_send(Return, room.seats[room.curr_turn].player.pid, pack_protocol("sc_game_qdz", {}))
end

function on_game_action_qdz(player, packe)
    local room = player.room
    if room.status ~= room_qiangdizhu then return end

    player.seat.qdz = packet.action
    room.waiting_actions[player.seat_index] = nil

    local Return = {}
    --local content = {seat_index = player.seat_index, action_id = protocol.game_action_qdz, action = packet.action}
    --local packet_bin = pack_protocol("sc_game_action", content)
    --broadcast_packet(Return, room, packet_bin)
    if packet.action == 1 then --抢地主
        room.waiting_actions = {}
        room.dizhu_seat = player.seat_index
        room.curr_turn = player.seat_index
        for i, v in ipairs(room.dizhu_pokers) do
            table.insert(player.seat.hand_seq, v)
        end
        helper_game_start_jiabei(Return, room)
    else
        local all_reply = true
        for i, v in ipairs(room.seat_index) do
            if (v.qdz == -1) then 
                all_reply = false
                break
            end
        end

        if all_reply then   --没人抢地主,开始下一局
            return helper_game_start(room, Return)
        end
        set_next_turn(room)
        helper_game_start_qdz(Return, room)
    end

    return Return
end

function helper_game_start_jiabei(Return, room)
    if room.status ~= room_jiabei then
        room.status = room_jiabei

        room.waiting_actions = {}
        for i, v in ipairs(room.seats) do
            room.waiting_actions[i] = {action_id = protocol.game_action_jiabei}
        end

        local packet_bin = pack_protocol("sc_game_change_status", {room_status = room_jiabei})
        broadcast_packet(Return, room, packet_bin)
    end
end

function on_game_action_jiabei(player, packe)
    local room = player.room
    if room.status ~= room_jiabei then return end

    player.seat.jiabei = packet.action
    room.waiting_actions[player.seat_index] = nil

    local Return = {}
    local content = {seat_index = player.seat_index, action_id = protocol.game_action_qdz, action = packet.action}
    local packet_bin = pack_protocol("sc_game_action", content)
    broadcast_packet(Return, room, packet_bin)

    local all_reply = true
    for i, v in ipairs(room.seats) do
        if v.jiabei == -1 then
            all_reply = false
            break
        end
    end

    if all_reply == true then
        --kill_timer(protocol.game_action_jiabei)
        helper_game_start_chupai(Return, room)
    end
end

function helper_game_start_chupai(Return, room)
    if room.status ~= room_gaming then
        room.status = room_gaming
        local packet_bin = pack_protocol("sc_game_change_status", {room_status = room_gaming})
        broadcast_packet(Return, room, packet_bin)
    end

    set_turn_waiting_action(room, protocol.game_action_chupai)

    --broadcast_packet_except(Return, room, pack_protocol("sc_game_action", {})
end

function on_game_action_chupai(player, packet)
    local pokers = packet.what
    local room = player.room

    if room.curr_turn ~= player.seat_index then return end

    local Return = {}
    if #pokers == 0 then    -- 不要
        if player.seat_index == room.banker_seat then return end    --不能过
        player.seats.last_chu = {
            poksers_type = 0,
            pokers_point = 0,
            pokers = nil
        }
    else
        -- check pokers type, compare
        local poksers_type, pokers_point = poker.pokers_type_check(pokers)
        if poksers_type == 0 then return end

        local last_chu = room.seats[room.banker_seat].last_chu
        local pokers_compare = false
        if player.seat_index ~= room.banker_seat then
            if (poksers_type == poker.BOMB_POKERS and last_chu.poksers_type ~= poker.BOMB_POKERS) or
            (poksers_type == last_chu.poksers_type and pokers_point < last_chu.pokers_point and #pokers == #last_chu.pokers) then
                pokers_compare = true
            end
        else
            pokers_compare = true
        end

        if pokers_compare == false then return end

        -- check hand_seq
        if #player.seat.hand_seq < #pokers then
            return
        end

        local hand_seq = player.seat.hand_seq
        for i1, v1 in ipairs(pokers) do
            local poker_sure = false
            for i2, v2 in ipairs(hand_seq) do
                if (v2 == v1) then
                    poker_sure = true
                    break
                end
            end

            if poker_sure == false then
                return
            end
        end

        -- remove pokers
        for i1, v1 in ipairs(pokers) do
            local remove_sure = false
            for i2, v2 in ipairs(hand_seq) do
                if (v1 == v2) then 
                    remove_sure = true
                    table.remove(hand_seq, i2) 
                    break
                end
            end

            if remove_sure == false then
                assert(false)
            end
        end

        room.banker_seat = player.seat_index
        player.seats.last_chu = {
            poksers_type = poksers_type,
            pokers_point = pokers_point,
            pokers = pokers
        }

        if helper_check_game_over then
            game_over(Return, room)
        end
    end

    room.waiting_actions[room.curr_turn] = nil
    set_next_turn(room)
    set_turn_waiting_action(room, protocol.game_action_chupai)

    return Return
end

function helper_check_game_over(seat)
    if #seat.hand_seq == 0 then
        return true
    else
        return false
    end
end

function game_over(Return, room)
    room.waiting_actions = nil
    room.status = room_game_over

    local packet = {}
    packet.player_pokers = {}
    for i, v in ipairs(room.seats) do
        packet.player_pokers[i] = {}
        table.insert(packet.player_pokers, v.hand_seq)
    end

    local packet_bin = pack_protocol("sc_game_over", packet)
    broadcast_packet(Return, room, packet_bin)
end

function set_next_turn(room)
    room.curr_turn = get_net_seat_index(room.curr_turn)
end

function set_turn_waiting_action(room, action_id)
    if room.curr_turn < 1 or room.curr_turn > #room.seats then return end
    room.waiting_actions = {}
    room.waiting_actions[room.curr_turn] = {action_id = action_id}
end

function get_net_seat_index(seat_index)
    if seat_index < #room.seats then
        return seat_index + 1
    else
        return 1
    end
end

function on_cs_add_bot()

end

function on_cs_game_debug_time()

end

function on_cs_dismiss_room()

end

function on_cs_game_auto()

end

function on_cs_gift_action()

end

function on_timer(roomid, TimerID)
    print("on_timer, roomid:",roomid,", TimerID:", TimerID)
    local room = global_rooms[roomid]
    local handler = global_game_timeout_handlers[TimerID]

    if handler ~= nil and room ~= nil then
        local Return = {}
        return handler(Return, room)
    end
end

function on_game_timeout_mingpai(Return, room)
    if room.status ~= room_sendpokers then return end
    room.waiting_actions = nil
    helper_game_start_qdz(Return, room)
end

function on_game_timeout_qdz(Return, room)
    if room.status ~= room_qiangdizhu then return end

    local seat_index = room.curr_turn
    if room.waiting_actions[seat_index] == nil or room.waiting_actions[seat_index].action_id ~= protocol.game_action_qdz then return end
    room.waiting_actions[seat_index] = nil
    room.seats[seat_index].qdz = 0

    local content = {seat_index = seat_index, action_id = protocol.game_action_qdz, action = 0}
    local packet_bin = pack_protocol("sc_game_action", content)
    broadcast_packet(Return, room, packet_bin)
    
    set_next_turn(room)
    helper_game_start_qdz(Return, room)

    return Return
end

function on_game_timeout_jiabei(Return, room)
    if room.status ~= room_jiabei then return end
    room.waiting_actions = nil
    
    for i, v in ipairs(room.seats) do
        if v.jiabei == -1 then
            local content = {seat_index = i, action_id = protocol.game_action_jiabei, action = 0}
            local packet_bin = pack_protocol("sc_game_action", content)
            broadcast_packet(Return, room, packet_bin)
        end
    end

    helper_game_start_chupai(Return, room)

    return Return
end

function on_game_timeout_chupai(Return, room)
    if room.status ~= room_gaming then return end
    room.waiting_actions = {}
    local player = room.seats[room.curr_turn].player
    room.seats[room.curr_turn].last_chu = {
        poksers_type = 0,
        pokers_point = 0,
        pokers = nil
    }

    set_next_turn(room)
    set_turn_waiting_action(room, protocol.game_action_chupai)
end

function broadcast_packet(Return, room, packet)
    for i, v in ipairs(room.seats) do
        add_send(Return, v.player.pid, packet)
    end
end

function get_player_by_packet(packet)
    
end

function pack_protocol_to_bin(_id, _content)
    assert(type(_content) == 'table' or _content == nil)
    if _content == nil then
       return protobuf.encode("gameserver.protocol", {id = protocol.get_id(_id)})
    else
       return protobuf.encode("gameserver.protocol", {id = protocol.get_id(_id), content = 
                                                      pack_content_to_bin("gameserver." .. _id,  _content)})
    end
 end
 
function pack_protocol(_id, _content)
    assert(type(_content) == 'table' or _content == nil)
    if _content == nil then
        return {id = protocol.get_id(_id)}
    else
        return {id = protocol.get_id(_id), content = 
               pack_content_to_bin("gameserver." .. _id,  _content)}
    end
end
 
 function pack_content_to_bin(desc, t)
    assert(type(t) == 'table')
    return protobuf.encode(desc, t)
 end

function broadcast_packet_except(Return, seats, bin, pid, super_bin)
    for i, v in ipairs(seats) do
        if v ~= none and v.player.pid ~= pid then
            if (v.player.super and super_bin) then
                add_send(Return, v.player.pid, super_bin)
            else
                add_send(Return, v.player.pid, bin)
            end
        end
    end
end

function pack_return(Return)

    pack_send(Return)

    return Return
end

function pack_send(Return)
    for i, v in ipairs(Return) do
        local op = v[1]
        local args = v[2]
 
        if (op == 'send') then
            local union_bin = pack_protocol_to_bin("sc_protocol_pack",
                                                   {
                                                      pack = args[2] 
                                                   })
            args[2] = union_bin
        end
    end   
end

function add_timer(Return, roomid, timerid, time)
    table.insert(Return, {'start_timer', {roomid, timerid, time}})
end

function kill_timer(Return, roomid, timerid)
    table.insert(Return, {'kill_timer', {roomid, timerid}})
end

--[[function test_add_timer()
    local Return = {}
    table.insert(Return, {'start_timer', {1, 1, 10}})
    return Return
end

function test_kill_timer()
    local Return = {}
    table.insert(Return, {'kill_timer', {1, 1}})
    return Return
end]]

register_packet_handler()
register_game_action_handler()
register_game_timeout_handler()
