local socket = require "socket"
print("classic_ddz lua module is loaded", socket.gettime())

local protobuf = require "protobuf"

require("opcode_common")
require("utility_common")
require("log_common")

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
local room_jiaodizhu             = 3
local room_qiangdizhu            = 4
local room_jiabei            	 = 5
local room_gaming                = 6
local room_game_over             = 7

local room_timer = {
    [protocol.game_action_mingpai] = {id = protocol.game_action_mingpai, time = 5},
    [protocol.game_action_jdz] = {id = protocol.game_action_jdz, time = 10},
    [protocol.game_action_qdz] = {id = protocol.game_action_qdz, time = 10},
    [protocol.game_action_jiabei] = {id = protocol.game_action_jiabei, time = 5},
    [protocol.game_action_chupai] = {id = protocol.game_action_chupai, time = 20},
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
        --gametype = 'classic_ddz', --gametype,
        --game_config = game_config,

        last_chued_seat_index = 0,
        banker_seat = 0, 
        dizhu_seat = 0,
        curr_turn = 0,
        next_turn = 0,
        beishu = 1,
        first_mingpai_seat = 0,  --第一个明牌的玩家

        poker = nil,
        chued_seqs = {},
        dizhu_pokers = {}, --三张地主牌
        player_count = 0,
        passwd = none,

        jdz_liuju = 0,
 
        --public wating action
        --可能有多个玩家，多个action
        waiting_actions = nil, 

        timeout_info = {start_time = 0, timeout = 0},

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
    --self.seats = {none, none, none}

    --self.operate_seat = nil
 
    self.first_mingpai_seat = 0
    self.curr_turn = 0
    self.dizhu_seat = 0
    self.last_chued_seat_index = 0
    self.banker_seat = 0
    self.poker = nil
    self.chued_seqs = {}
    self.dizhu_pokers = {}
 
    self.timeout_info = {start_time = 0, timeout = 0}
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
 
            --v.action_seq = nil
            v.action_bin = nil
 
            v.hand_seq 	= {}
         
            v.auto = false
            v.ready = false
            v.ingame=false
            v.inroom=true
            v.last_chu = {}
            v.chued_seq = {}
            v.chued_count = 0

            v.jdz = -1
            v.qdz   = -1 
            v.jiabei     = -1
            v.mingpai = -1
        end
    end
end

function reset_seats_status(room)
    room.poker = nil
    room.dizhu_pokers = {}
    room.play_seats = {}
    room.curr_turn = 0
    room.dizhu_seat = 0
    room.last_chued_seat_index = 0
    room.banker_seat = 0
    for i, v in ipairs(room.seats) do
        if v ~= none then
            v.hand_seq 	= {}
            v.jdz = -1
            v.qdz   = -1 
            v.jiabei     = -1
            v.mingpai = -1
            v.auto = false
        end
    end
end

global_packet_handlers = {}
global_game_action_handlers = {}
global_game_timeout_handlers = {}

function register_packet_handler()
    --global_packet_handlers["cs_player_enter_room"]  = on_cs_player_enter_room
    global_packet_handlers["cs_game_action"]        = on_cs_game_action
    global_packet_handlers["cs_ready_game"]         = on_cs_ready_game
    global_packet_handlers["cs_change_online"]      = on_cs_change_online
    global_packet_handlers["cs_leave_room"]         = on_cs_leave_room 
    global_packet_handlers["cs_add_bot"]	        = on_cs_add_bot
    global_packet_handlers['cs_game_debug_time']    = on_cs_game_debug_time
    global_packet_handlers["cs_dismiss_room"]       = on_cs_dismiss_room
    global_packet_handlers["cs_game_auto"]          = on_cs_game_auto
    global_packet_handlers["cs_gift_action"]        = on_cs_gift_action
    global_packet_handlers["cs_use_prop"]           = on_cs_use_prop
    global_packet_handlers["cs_game_auto"]			= on_cs_game_auto
    global_packet_handlers["cs_game_manual"]		= on_cs_game_manual
end

function register_game_action_handler()
    global_game_action_handlers[protocol.game_action_mingpai]   = on_game_action_mingpai  --无顺序
    global_game_action_handlers[protocol.game_action_jdz]       = on_game_action_jdz
    global_game_action_handlers[protocol.game_action_qdz]       = on_game_action_qdz
    global_game_action_handlers[protocol.game_action_jiabei]    = on_game_action_jiabei --无顺序
    global_game_action_handlers[protocol.game_action_chupai]    = on_game_action_chupai
end

function register_game_timeout_handler()
    global_game_timeout_handlers[protocol.game_action_mingpai]  = on_game_timeout_mingpai
    global_game_timeout_handlers[protocol.game_action_jdz]      = on_game_timeout_jdz
    global_game_timeout_handlers[protocol.game_action_qdz]      = on_game_timeout_qdz
    global_game_timeout_handlers[protocol.game_action_jiabei]   = on_game_timeout_jiabei
    global_game_timeout_handlers[protocol.game_action_chupai]   = on_game_timeout_chupai
end

--function player_on_packet(oid, packet_bin, roomid)
function onmessage(oid, packet_bin)
	local player = global_players[oid]
	if (player == nil) then
		return
    end
    
    local room = player.room
    if room == nil then
		return
	end

	--[[if room.roomid ~= roomid then
		local Return = {}
		add_error_log(Return, string.format('packet to room:%d, but player in room:%d', roomid, room.roomid))
		return Return
    end]]
    
	--unpack packet
	local protocol_id, protocol_content = 
	protocol.game_protocol_unpack_bin(packet_bin)

	if (not protocol_id) or (not protocol_content) then
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

	if handler ~= nil then
		return handler(player, protocol_content)
	else
        if DEBUG then print(protocol_id) end
		return return_unhandle_when_debug(player.pid) 
	end
end

function player_disconnect(oid)
    local player = global_players[oid]
    if player == nil then return end
    local room = player.room
    local seat = player.seat

    if (room == nil or seat == nil) then
        return
    end

    local Return = {}
    if room.status == room_not_gaming then
        make_player_leave(Return, oid)
    elseif room.status == room_game_over then
        make_player_leave(Return, oid)
    else
        player.online = false
        broadcast_packet_except(Return, 
                            room.seats, 
                            pack_protocol("sc_change_online", {seat_index=seat.index, online=false}),
                            player.pid 
                            )
    end

    return pack_return(Return)
end

---切换成自动
function on_cs_game_auto(player, packet)
    local Return = {}
    local room = player.room
    local seat = player.seat

    if (room == nil or seat == nil) then
        return
    end

    --seat.auto_count = 0;
    seat.auto = true

    add_send(Return, player.pid, pack_protocol("sc_game_auto",
    {
        auto = true
    })
    )

    broadcast_packet_except(Return, room, pack_protocol("sc_game_auto_notify",
    {
        seat_index = seat.index,
        auto = true
    }),
    player.pid)

    return pack_return(Return)
end

---切换成手动
function on_cs_game_manual(player, packet)
    local Return = {}
    local room = player.room
    local seat = player.seat

    if (room == nil or seat == nil) then
        return
    end

    --seat.auto_count = 0
    seat.auto = false

    add_send(Return, player.pid, pack_protocol("sc_game_auto",
    {
        auto = false
    })
    )

    broadcast_packet_except(Return, room, pack_protocol("sc_game_auto_notify",
    {
        seat_index = seat.index,
        auto = false
    }),
    player.pid)

    return pack_return(Return)

end

--踢到玩家的方法
function make_player_leave(Return, oid, why, not_send_leave)
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

    --if room.player_count > 0 then room.player_count = room.player_count - 1 end

    --local Return = {}
    if not not_send_leave then
        add_send(Return, player.pid, pack_protocol("sc_leave_room",
        {
            result = 0,
            reason = 0,
            why = why
        })
        )
    end

    broadcast_packet_except(Return, room.seats, pack_protocol("sc_leave_room_notify",
    {
        seat_index = seat.index,
    }),
    player.pid)

    room.seats[seat.index] = none
    player:reset()

    add_close_player(Return, player.pid, 'player_leave')

    room.player_count = change_public_room_tree(room.roomid)

    --if is_custom(room) then
    --    change_room_player_count(Return, room)
    --end

    --没有玩家的时候就把状态设置为room_not_gaming
    --[[if player_count == 0 then
        room.status = room_not_gaming
        room.game_over_uuid = nil
    end]]

    --return pack_return(Return)
end

function helper_game_start(room, Return)
    room.game_log.room_info = room.game_log.room_info or {}
    --room.game_log.room_info.game_config = room.game_config
    room.game_log.log = {} --详细游戏日志
    room.game_log.log.gameing = {}
    local now = os.time() 

    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    room.poker = pokers_module.normal_shuffle_tiles()

    room.log_uid = getUUID()
    --清空上一场日志
	room.game_log.begin_time = now    --开始时间

    room.chued_seqs = {}
    room.waiting_actions = {}

    -- rand first operate player
    room.status = room_sendpokers
room.game_log.player_infos = {}
    for i, v in ipairs(room.seats) do
        if v ~= none then
            v.point = v.point or 0
	        v.ingame=true

            table.insert(room.play_seats, v)

            room.game_log.player_infos[i] = {
                gold = v.player.gold or 0,
                seat_index = i,
                nick_name = v.player.nick_name or 'user',
                portrait = v.player.portrait or '',
                sex = v.player.sex or 0,
                oid = v.player.oid
            }

            --table.insert(room.game_log.players, v.player.oid) 
        end
    end

    assert(game_player_count == #room.play_seats)

    for i, v in ipairs(room.seats) do
        assert(v ~= nil)
        
        for i=1, 17 do
            table.insert(v.hand_seq, pokers_module.deal_poker(room.poker))
        end

        if v.mingpai == -1 then
            room.waiting_actions[i] = {action_id = {protocol.game_action_mingpai}}
        end
    end
    for i=1, 3 do
        table.insert(room.dizhu_pokers, pokers_module.deal_poker(room.poker))
    end

    local record_seat_info = {}
    for i, v in ipairs(room.seats) do
        add_send(Return, v.player.pid, pack_protocol(
                    "sc_start_game", 
                    {
                        other_infoes = pokers_module.notify_other_hand_seq(room, i, 17),
                        you_seq_info = {seat_index = i, ['hand_seq'] = {count = #v.hand_seq, pokers = v.hand_seq}},
                        --tiles_remain	= #room.remain,
                        banker_seat = room.banker_seat
                    }))

        if v.mingpai == -1 then
            add_send(Return, v.player.pid, pack_protocol("sc_game_show_actions",
                    {
                        timeout = room_timer[protocol.game_action_mingpai].time,
                        show_actions = {protocol.game_action_mingpai}
                    }))
        end

        local pokers = {}
        for i, v in ipairs(v.hand_seq) do table.insert(pokers, v) end
        table.insert(record_seat_info, {
            seat_index = i,
            hand_seq = pokers,
            mingpai = v.mingpai > 0 and 1 or 0
        })
    end

    room.game_log.log.start = {
        msg_type = "record_start_game",
        --banker_seat = room.banker_seat,
        --curr_turn = room.curr_turn,
        seat_info = record_seat_info
    }

    room.timeout_info = {start_time = now, timeout = room_timer[protocol.game_action_mingpai].time}
    add_timer(Return, room.roomid, protocol.game_action_mingpai, room_timer[protocol.game_action_mingpai].time, '')
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
                    action_seq  = getUUID(),
                    action_bin  = nil,
               
                    ready=false,
                
                    hand_seq= {},
                    last_chu = {},
                    chued_seq = {},
                    chued_count = 0,
              
                    auto = false,
                    ingame = false,
                    inroom = true,
                
                    mingpai = -1,
                    jiabei = -1,
                    qdz = -1,
                    jdz = -1
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
            print("player continue game, ", player.oid)
        end
    end

    if enter_room_succ == false then
        print("player enter room faild, ", player.oid)
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
                                 --id       = player.id,
                                 --idtype   = player.idtype,
                                 nick_name= player.nick_name or 'user',
                                 gold		= player.gold or 0,
                                 sex		= player.sex or 0,
                                 --portrait = player.portrait,
                                 --ip       = player.peer_host,
                                 exp      = player.exp or 0,
                                 online   = player.online,
                                 --signature = player.signature
                              },
                              ready       = v.ready,
                              --hand_seq    = v.hand_seq,
                              --last_chu    = v.last_chu,
                              money       = v.point or 0,
                           })
            else
                table.insert(_seat_infoes, 
                           {		
                              seat_index  = i,
                              player_info = {
                                 oid      = player.oid,
                                 --id       = player.id,
                                 --idtype   = player.idtype,
                                 nick_name= player.nick_name  or 'user',
                                 gold		= player.gold or 0,
                                 sex		= player.sex or 0,
                                 --portrait = player.portrait,
                                 --ip       = player.peer_host,
                                 exp      = player.exp or 0,
                                 online   = player.online,
                                 --signature = player.signature
                              },
                              ready       = v.ready,
                             -- hand_seq    = {}, --mahjong.notify_hand_seq(v.hand_seq, player.super),
                              --last_chu    = v.last_chu,
                              money       = v.point or 0
                           })
  
            end
        end 
    end

    add_send(Return, player.pid, pack_protocol(
                  "sc_enter_room",
                  {seat_index	 = player.seat_index,
                   seat_infoes   = _seat_infoes,
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

    broadcast_packet_except(Return, room.seats, pack_protocol("sc_enter_room_notify", 
                                {seat_info = {
                                    seat_index = player.seat_index,
                                    ready = player.seat.ready,
                                    player_info = {
                                       oid = player.oid,
                                       gold = player.gold or 0,
                                       sex  = player.sex or 0,
                                       --portrait = player.portrait,
                                       --ip   = player.peer_host,
                                       nick_name = player.nick_name or 'user',
                                       exp  = player.exp or 0,
                                       online = player.online,
                                       --signature = player.signature
                                    }
                                }}),
                                player.pid)

    --room.player_count = room.player_count + 1
    room.player_count = change_public_room_tree(room.roomid)

    return room_id, pack_return(Return)
end

function player_continue_game(oid, roomid)
    local Return = {}
	local player = global_players[oid]

	local time = os.time()

	if (player == nil) then
		return
	end
    player.online = true

    if DEBUG then print("fuck 1") end

	local pid = player.pid
	local seat = player.seat
	local room = player.room

    if DEBUG then print("fuck 2:", room.roomid, roomid) end

	if room ~= nil then
		if room.roomid ~= roomid then
			return
		end
	end

    if DEBUG then print("fuck 3") end
	if room == nil then
		local Return = {}
		add_close_player(Return, pid, 'continue_but_no_room')
		return Return
	end

    if DEBUG then print('-----------------------------------'..'sc_continue_game') end
    --[[if player.room.is_match_room then
        return player_continue_match_room(caller, player)
    end]]

    local dismiss_info = {}
   
    if room.dismiss_apply then
        for i, v in ipairs(room.seats) do
            table.insert(dismiss_info, {seat_index=i, dismiss=v.dismiss})
        end
    end

    local _seat_infoes = {}
   
    if (room.status == room_not_gaming) then
        for i, v in ipairs(room.seats) do
            if v ~= none then
                local player1 = v.player
                table.insert(_seat_infoes, 
                        {		
                            seat_index  = i,
                            ready       = v.ready,
                            money       = v.point,
                            player_info = {
                               oid 		= player1.oid, 
                               id       = player1.id,
                               idtype   = player1.idtype,
                               nick_name= player1.nick_name,
                               gold		= player1.gold,
                               sex		= player1.sex,
                               portrait = player1.portrait,
                               ip       = player1.peer_host,
                               exp      = player1.exp,
                               online   = player1.online,
                               signature = player1.signature
                        }})
            end
        end
        if DEBUG then print('sc_enter_room') end
        add_send(Return, pid, pack_protocol(
                  "sc_enter_room",
                  {seat_index	 = seat.index,
                   seat_infoes = _seat_infoes,
                   --room_pwd = room.passwd,
			   	   --roomid = room.roomid,
                   --room_base = room.place_config.base_zhu,
                   --game_config = encode_json(room.game_config),
                   --place = room.place_id,
                   --gametype = room.gametype,
                   --current_round = room.ju_count+1,
                   --owner_seat = room.owner and room.owner.seat_index or 0,
                   --dismiss_apply = room.dismiss_apply,
                   --dismiss_second = dismiss_time,
                   --dismiss_info = dismiss_info,
                   --creater_id = room.creater_id,
                   --creater_type = room.creater_type
               }))

        return pack_return(Return)
    end

    -- 0:游戏开始 15:开始定缺 16:开始出牌
    for i, v in ipairs(room.seats) do
        if v ~= none then
            local player1 = v.player

            if (i == seat.index) then
                local  v_hand_seq = {
                    pokers = v.hand_seq,
                    count = #v.hand_seq
                }
                table.insert(_seat_infoes, 
                         {		
                            seat_index  = i,
                            player_info = {
                               oid 		= player1.oid, 
                               id       = player1.id,
                               idtype   = player1.idtype,
                               nick_name= player1.nick_name,
                               gold		= player1.gold,
                               sex		= player1.sex,
                               portrait = player1.portrait,
                               ip       = player1.peer_host,
                               exp      = player1.exp,
                               online   = player1.online,
                               signature = player1.signature
                            },
                            ready       = v.ready,
                            mingpai     = v.mingpai > 0 and true or false,     
                            jdz         = v.jdz > 0 and 1 or 0,
                            qdz         = v.qdz > 0 and 1 or 0,
                            jiabei      = v.jiabei > 0 and v.jiabei or 0,
                            hand_seq    = v_hand_seq,
                            money       = v.point,
                            chued_seq_type = v.last_chu.pokers_type ~= nil and v.last_chu.pokers_type or -1,
                            chued_seq = v.last_chu.pokers,
                            all_chued_seq = #v.chued_seq > 0 and v.chued_seq or nil
                         })
            else
                local  v_hand_seq = {
                    pokers = v.mingpai > 0 and v.hand_seq or nil,
                    count = #v.hand_seq
                }
                table.insert(_seat_infoes, 
                         {		
                            seat_index  = i,
                            player_info = {
                               oid      = player1.oid,
                               id       = player1.id,
                               idtype   = player1.idtype,
                               nick_name= player1.nick_name,
                               gold		= player1.gold,
                               sex		= player1.sex,
                               portrait = player1.portrait,
                               ip       = player1.peer_host,
                               exp      = player1.exp,
                               online   = player1.online,
                               signature = player1.signature
                            },
                            ready       = v.ready,
                            mingpai     = v.mingpai > 0 and true or false,     
                            jdz         = v.jdz > 0 and 1 or 0,
                            qdz         = v.qdz > 0 and 1 or 0,
                            jiabei      = v.jiabei > 0 and v.jiabei or 0,
                            hand_seq    = v_hand_seq,
                            money       = v.point,
                            chued_seq_type = v.last_chu.pokers_type ~= nil and v.last_chu.pokers_type or -1,
                            chued_seq = v.last_chu.pokers,
                            all_chued_seq = #v.chued_seq > 0 and v.chued_seq or nil
                         })

            end
        end
    end

    local show_actions = nil
    if room.waiting_actions ~= nil and room.waiting_actions[seat.index] ~= nil then
        show_actions = room.waiting_actions[seat.index].action_id
    end
    local room_chued_seq = nil
    if room.dizhu_seat > 0 and #room.seats[room.dizhu_seat].hand_seq < 20 then
        room_chued_seq = room.chued_seqs
    end

    local turn_time = 0
    if room.timeout_info.timeout ~= 0 then
        local now = os.time()
        turn_time = room.timeout_info.timeout - (now - room.timeout_info.start_time)
        if turn_time < 0 then turn_time = 0 end
    end

    if DEBUG then print('sc_continue_game') end
    add_send(Return, pid, pack_protocol(
               "sc_continue_game",
               {dizhu_seat = room.dizhu_seat,
                dizhu_pokers = room.dizhu_seat ~= 0 and room.dizhu_pokers or nil,
                seat_index	 = seat.index,
                --lack_second = lack_time,
                turn_second = turn_time,
                room_status = room.status,
                curr_turn   = room.curr_turn,
                beishu = room.beishu,
                --thinking	 = _thinking,
                --think_second= think_time,
                --room_pwd = room.passwd,
                show_actions = show_actions,
                seat_infoes = _seat_infoes,
                room_chued_seq = room_chued_seq,
                --tiles_remain	= #room.remain,
                --roomid	     = room.roomid,
                --room_base = room.place_config.base_zhu,
                --current_round = room.ju_count,
                --game_config = encode_json(room.game_config),
                --place = room.place_id,
                gametype = room.gametype,
                --owner_seat = room.owner and room.owner.seat_index or 0,
                --dismiss_apply = room.dismiss_apply,
                --dismiss_second= dismiss_time,
                --dismiss_info = dismiss_info,
                last_chued_seat_index = room.last_chued_seat_index,
                --creater_id = room.creater_id,
                --creater_type = room.creater_type
               }))

    if room.dismiss then
        add_send(Return, pid, pack_protocol(
                                 "sc_end_game",
                                 {
                                    --['liuju'] = room.liuju,
                                    seq_infos = room.ju_infos[#room.ju_infos],
                                    current_round = room.ju_count,
                                    total_round = room.game_config.ju_count,
                                    is_game_group_end = true
                                }))
        add_send(Return, pid, pack_protocol(
                                "sc_end_game_group",
                                {
                                    game_seq_infos = room.ju_infos,
                                    --consume_card   = room.consume_card,
                                    --first_round_start_time = room.group_start_time or 0
                                }))
    end

    broadcast_packet_except(Return, 
                            room.seats, 
                            pack_protocol("sc_change_online", {seat_index=player.seat_index, online=true}),
                            player.pid 
                            )
   
    return pack_return(Return)
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

    seat.ready = true
    local all_ready = true
    for i, v in ipairs(room.seats) do
        if v == none or v.ready == false then
            all_ready = false
            break
        end
    end

    if packet.mingpai == 1 then seat.mingpai = 5 end

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
    local Return = {}

    local room = player.room
    local seat = player.seat

    if room == nil or seat == nil then
        return
    end

    print("cs_change_online")

    broadcast_packet_except(Return, 
                            room.seats, 
                            pack_protocol("sc_change_online", {seat_index=seat.index, online=packet.online}),
                            player.pid 
                            )

    return pack_return(Return)
end

function on_cs_leave_room(player, packet)
    if DEBUG then print("on_cs_leave_room") end

    local room = player.room

    if (room == nil) or (room.status ~= room_game_over and room.status ~= room_not_gaming) then
        return
    end

    --自定义房间，没有这种方法
    
    local Return = {}
    if packet.why == 'client_disconnect' then
        return
    end
 
    make_player_leave(Return, player.oid, 'manual_leave') 

    return pack_return(Return)
end

function on_cs_game_action(player, packet)
    local room = player.room  
    local _action_id = packet.id

    local handler = nil
    --[[if (room.status == room_sendpokers or room.status == room_jiabei) then
        handler = global_game_action_handlers[_action_id]
        if handler ~= nil then
            return handler(player, content_lua)
        end
    end]]
    if room.waiting_actions == nil or room.waiting_actions[player.seat_index] == nil or room.waiting_actions[player.seat_index].action_id == nil then 
        return
    end

    local user_actions = room.waiting_actions[player.seat_index].action_id
    if #user_actions == 0 then return end

    local check_action = false
    for i, v in ipairs(user_actions) do
        if v == _action_id then 
            check_action = true
            break
        end
    end

    if check_action == false then return false end
    
    handler = global_game_action_handlers[_action_id]

    if handler ~= nil then
       return handler(player, packet)
    else
       --return return_unhandle_when_debug(player.pid)
    end
end

function on_game_action_mingpai(player, packet)
    local room = player.room
    if player.seat.mingpai ~= -1 then return end

    player.seat.mingpai = packet.reply

    if packet.reply == 1 then
        if room.status == room_sendpokers then
            local now = os.time()
            if now - room.game_log.begin_time <= 2 then
                player.seat.mingpai = 4
            else
                player.seat.mingpai = 3
            end
        elseif room.status == room_gaming then
            player.seat.mingpai = 2
        end
        --player.seat.mingpai = room.status == room_gaming and 4 or 2
        if room.first_mingpai_seat == 0 then room.first_mingpai_seat = player.seat_index end
    end

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_mingpai,
        act_seat_index = player.seat_index,
        reply = packet.reply
    }
    table.insert(room.game_log.log.gameing, record_game_action)
    
    local Return = {}
    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_mingpai, act_reply = packet.reply}))
    if packet.reply == 1 then --明牌
        local content = {act_id = protocol.game_action_mingpai, act_reply = packet.reply, act_seat_index = player.seat_index, acted_hand_seq = {pokers = player.seat.hand_seq, count = #player.seat.hand_seq}}
        broadcast_packet_except(Return,
                   room.seats,
                   pack_protocol("sc_game_action_notify", content),
                   player.pid
                  )
    end

    if room.status == room_sendpokers then
        room.waiting_actions[player.seat_index] = nil
        local all_sure = true
        for i, v in ipairs(room.seats) do
            if (v.mingpai == -1) then 
                all_sure = false
                break
            end
        end

        if (all_sure == true) then
            kill_timer(Return, room.roomid, protocol.game_action_mingpai, '')
            helper_game_start_jdz(Return, room)
        end
    end

    return pack_return(Return)
end

function helper_game_start_jdz(Return, room)
    if (room.status ~= room_jiaodizhu) then
        room.status = room_jiaodizhu
        if room.first_mingpai_seat ~= 0 then
            room.curr_turn = room.first_mingpai_seat
        else 
            room.curr_turn = math.random(#room.play_seats)
        end
        --local packet_bin = pack_protocol("sc_game_action", {room_status = room_qiangdizhu})
        --broadcast_packet(Return, room, packet_bin)
    end
    
    set_turn_waiting_action(room, {protocol.game_action_jdz})
    set_turn_timer(Return, room, protocol.game_action_jdz)

    add_send(Return, room.seats[room.curr_turn].player.pid, pack_protocol("sc_game_turn",
                     {
                        timeout = room_timer[protocol.game_action_jdz].time,
                        show_actions = {protocol.game_action_jdz}
                     }))

    local content = {timeout = room_timer[protocol.game_action_jdz].time, seat_index = room.curr_turn}
    broadcast_packet_except(Return,
                   room.seats,
                   pack_protocol("sc_game_turn_notify", content),
                   room.seats[room.curr_turn].player.pid
                  )
end

function on_game_action_jdz(player, packet)
    local room = player.room
    if room.status ~= room_jiaodizhu or player.seat_index ~= room.curr_turn then return end

    player.seat.jdz = packet.reply
    room.waiting_actions[player.seat_index] = nil

    local Return = {}
    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_jdz, act_reply = packet.reply}))
    local content = {act_id = protocol.game_action_jdz, act_reply = packet.reply, act_seat_index = player.seat_index}
    broadcast_packet_except(Return,
            room.seats,
            pack_protocol("sc_game_action_notify", content),
            player.pid
        )

    kill_timer(Return, room.roomid, protocol.game_action_jdz, player.seat.action_seq)

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_jdz,
        act_seat_index = player.seat_index,
        reply = packet.reply
    }
    table.insert(room.game_log.log.gameing, record_game_action)

    if packet.reply == 1 then
        local next_turn = 0
        for i = 1, #room.seats-1 do
            local next_seat = player.seat_index + i
            if next_seat > #room.seats then next_seat = next_seat - #room.seats end
            if room.seats[next_seat].jdz ~= 0 then
                next_turn = next_seat
                break
            end
        end
        if next_turn ~= 0 then
            room.curr_turn = next_turn
            helper_game_start_qdz(Return, room)
        else
            set_room_dizhu(room, player.seat_index)
            broadcast_dizhu_info(Return, room)
            helper_game_start_jiabei(Return, room)
        end
    else
        local next_seat = get_next_seat_index(room, player.seat_index)
        if room.seats[next_seat].jdz == -1 then
            set_next_turn(room)
            --set_turn_waiting_action(room, {protocol.game_action_jdz})
            helper_game_start_jdz(Return, room)
        else
            if room.jdz_liuju < 3 then
                room.jdz_liuju = room.jdz_liuju + 1
                reset_seats_status(room)
                helper_game_start(room, Return)
            else
                room.curr_turn = next_seat
                set_room_dizhu(room, next_seat)
                broadcast_dizhu_info(Return, room)
                helper_game_start_jiabei(Return, room)
            end
        end
    end

    return pack_return(Return)
end

function helper_game_start_qdz(Return, room)
    if (room.status ~= room_qiangdizhu) then
        room.status = room_qiangdizhu
    end
    
    set_turn_waiting_action(room, {protocol.game_action_qdz})
    set_turn_timer(Return, room, protocol.game_action_qdz)

    add_send(Return, room.seats[room.curr_turn].player.pid, pack_protocol("sc_game_turn",
                     {
                        timeout = room_timer[protocol.game_action_qdz].time,
                        show_actions = {protocol.game_action_qdz}
                     }))

    local content = {timeout = room_timer[protocol.game_action_qdz].time, seat_index = room.curr_turn}
    broadcast_packet_except(Return,
                   room.seats,
                   pack_protocol("sc_game_turn_notify", content),
                   room.seats[room.curr_turn].player.pid
                  )
end

function on_game_action_qdz(player, packet)
    local room = player.room
    if room.status ~= room_qiangdizhu then return end

    --player.seat.qdz = packet.reply
    room.waiting_actions = {}

    local Return = {}
    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_qdz, act_reply = packet.reply}))
    local content = {act_id = protocol.game_action_qdz, act_reply = packet.reply, act_seat_index = player.seat_index}
    broadcast_packet_except(Return,
            room.seats,
            pack_protocol("sc_game_action_notify", content),
            player.pid
        )

    kill_timer(Return, room.roomid, protocol.game_action_qdz, player.seat.action_seq)

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_qdz,
        act_seat_index = player.seat_index,
        reply = packet.reply
    }
    table.insert(room.game_log.log.gameing, record_game_action)

    if packet.reply == 1 then --抢地主
        room.beishu = room.beishu * 2
        if player.seat.jdz == 1 or player.seat.qdz == 1 then
            set_room_dizhu(room, player.seat_index)
            room.curr_turn = player.seat_index
            broadcast_dizhu_info(Return, room)
            helper_game_start_jiabei(Return, room)
        else
            local next_turn = 0
            for i = 1, #room.seats-1 do
                local next_seat = player.seat_index + i
                if next_seat > #room.seats then next_seat = next_seat - #room.seats end
                if room.seats[next_seat].qdz ~= 0 and room.seats[next_seat].jdz ~= 0 then
                    next_turn = next_seat
                    break
                end
            end
            assert(next_turn ~= 0)
            room.curr_turn = next_turn
            helper_game_start_qdz(Return, room)
        end
    else
        if player.seat.jdz == 1 then
            local qdz_seats = {}
            for i = 1, 2 do
                local seat = player.seat_index + i
                if seat > #room.seats then seat = seat - #room.seats end
                if room.seats[seat].qdz == 1 then table.insert(qdz_seats, seat) end
            end

            room.curr_turn = qdz_seats[1]
            if #qdz_seats == 1 then
                set_room_dizhu(room, qdz_seats[1])
                broadcast_dizhu_info(Return, room)
                helper_game_start_jiabei(Return, room)
            elseif #qdz_seats == 2 then
                helper_game_start_qdz(Return, room)
            end

            player.seat.qdz = packet.reply
            
            return pack_return(Return)
        end

        if player.seat.qdz == 1 then
            for i, v in ipairs(room.seats) do
                if i ~= player.seat_index and v.qdz == 1 then
                    room.curr_turn = i
                    set_room_dizhu(room, i)
                    break
                end
            end
            broadcast_dizhu_info(Return, room)
            helper_game_start_jiabei(Return, room)

            return pack_return(Return)
        end

        local jdz_seat = 0
        local next_qdz_seat = 0
        local qdz_seat = 0
        for i, v in ipairs(room.seats) do
            if i ~= player.seat_index and v.jdz == -1 and v.qdz == -1 then
                next_qdz_seat = i
            end

            if i ~= player.seat_index and v.jdz == -1 and v.qdz == 1 then
                qdz_seat = i
            end

            if v.jdz == 1 then
                jdz_seat = i
            end
        end

        if next_qdz_seat ~= 0 then
            player.seat.qdz = packet.reply
            room.curr_turn = next_qdz_seat
            --set_turn_waiting_action(room, {protocol.game_action_qdz})
            helper_game_start_qdz(Return, room)

            return pack_return(Return)
        end

        if next_qdz_seat == 0 and qdz_seat == 0 then
            room.curr_turn = jdz_seat
            set_room_dizhu(room, jdz_seat)
            broadcast_dizhu_info(Return, room)
            helper_game_start_jiabei(Return, room)
        else
            set_next_turn(room)
            helper_game_start_qdz(Return, room)
        end
    end

    player.seat.qdz = packet.reply

    return pack_return(Return)
end

function helper_game_start_jiabei(Return, room)
    if room.status ~= room_jiabei then
        room.status = room_jiabei

        room.timeout_info = {start_time = os.time(), timeout = room_timer[protocol.game_action_jiabei].time}
        add_timer(Return, room.roomid, protocol.game_action_jiabei, room_timer[protocol.game_action_jiabei].time, '')

        room.waiting_actions = {}
        for i, v in ipairs(room.seats) do
            room.waiting_actions[i] = {action_id = {protocol.game_action_jiabei}}
    
            add_send(Return, v.player.pid, pack_protocol("sc_game_show_actions",
                    {
                        timeout = room_timer[protocol.game_action_jiabei].time,
                        show_actions = {protocol.game_action_jiabei}
                    }))
        end
    end
end

function on_game_action_jiabei(player, packet)
    local room = player.room
    if room.status ~= room_jiabei then return end

    player.seat.jiabei = packet.reply
    room.waiting_actions[player.seat_index] = nil

    local Return = {}
    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_jiabei, act_reply = packet.reply}))
    local content = {act_id = protocol.game_action_jiabei, act_reply = packet.reply, act_seat_index = player.seat_index}
    broadcast_packet_except(Return,
               room.seats,
               pack_protocol("sc_game_action_notify", content),
               player.pid
              )

    local all_reply = true
    for i, v in ipairs(room.seats) do
        if v.jiabei == -1 then
            all_reply = false
            break
        end
    end

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_jiabei,
        act_seat_index = player.seat_index,
        reply = packet.reply
    }
    table.insert(room.game_log.log.gameing, record_game_action)

    if all_reply == true then
        --kill_timer(protocol.game_action_jiabei)
        kill_timer(Return, room.roomid, protocol.game_action_jiabei, '')
        helper_game_start_chupai(Return, room)
    end

    return pack_return(Return)
end

function helper_game_start_chupai(Return, room)
    if room.status ~= room_gaming then
        room.status = room_gaming
    end

    local actions = {protocol.game_action_chupai}
    if room.curr_turn == room.dizhu_seat and #room.seats[room.curr_turn].chued_seq == 0 and room.seats[room.curr_turn].mingpai == -1 then
        table.insert(actions, protocol.game_action_mingpai)
    end

    set_turn_waiting_action(room, actions)
    set_turn_timer(Return, room, protocol.game_action_chupai)

    add_send(Return, room.seats[room.curr_turn].player.pid, pack_protocol("sc_game_turn",
                     {
                        timeout = room_timer[protocol.game_action_chupai].time,
                        show_actions = actions
                     }))

    local content = {timeout = room_timer[protocol.game_action_chupai].time, seat_index = room.curr_turn}

    broadcast_packet_except(Return,
                   room.seats,
                   pack_protocol("sc_game_turn_notify", content),
                   room.seats[room.curr_turn].player.pid
                  )
end

function on_game_action_chupai(player, packet)
    local pokers = packet.pokers
    local room = player.room

    if room.curr_turn ~= player.seat_index then return end
    local pokers_type = 0
    local pokers_point = 0
    local Return = {}
local auto_test = pokers_module.get_auto_action_pokers(room)
    if #pokers == 0 then    -- 不要
        if player.seat_index == room.banker_seat or room.banker_seat == 0 then --不能过
            send_action_failed(Return, player.pid, protocol.game_action_chupai)
            return pack_return(Return)
        end
        player.seat.last_chu = {
            pokers_type = 0,
            pokers_point = 0,
            pokers = nil
        }
    else
        -- check pokers type, compare
        local banker_pokers_type = 0
        local banker_pokers_count = 0
        if room.banker_seat ~= 0 and room.banker_seat ~= player.seat_index and room.seats[room.banker_seat].last_chu.pokers ~= nil then
            banker_pokers_type = room.seats[room.banker_seat].last_chu.pokers_type
            banker_pokers_count = #room.seats[room.banker_seat].last_chu.pokers
        end

        pokers_type, pokers_point = pokers_module.pokers_type_check(pokers, banker_pokers_type, banker_pokers_count)
        if pokers_type == 0 then 
            send_action_failed(Return, player.pid, protocol.game_action_chupai)
            return pack_return(Return)
        end

        if room.banker_seat ~= 0 and room.banker_seat ~= player.seat_index then
            local last_chu = room.seats[room.banker_seat].last_chu
            local pokers_compare = false
            if player.seat_index ~= room.banker_seat then
                if (pokers_type == pokers_module.BOMB_POKERS and last_chu.pokers_type ~= pokers_module.BOMB_POKERS) or
                (pokers_type == last_chu.pokers_type and pokers_point > last_chu.pokers_point) then
                    pokers_compare = true    
                end
            else
                pokers_compare = true
            end

            if pokers_type ~= pokers_module.BOMB_POKERS and #pokers ~= #last_chu.pokers then
                pokers_compare = false
            end

            if pokers_compare == false then 
                send_action_failed(Return, player.pid, protocol.game_action_chupai)
                return pack_return(Return)
            end
        end

        -- check hand_seq
        if #player.seat.hand_seq < #pokers then
            send_action_failed(Return, player.pid, protocol.game_action_chupai)
            return pack_return(Return)
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
                send_action_failed(Return, player.pid, protocol.game_action_chupai)
                return pack_return(Return)
            end
        end

        player.seat.chued_count = player.seat.chued_count + 1
        -- remove pokers
        for i1, v1 in ipairs(pokers) do
            table.insert(room.chued_seqs, v1)
            table.insert(player.seat.chued_seq, v1)
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
        table.insert(player.seat.chued_seq, 0xFF)

        room.last_chued_seat_index = player.seat_index
        if pokers_type == pokers_module.BOMB_POKERS then room.beishu = room.beishu * 2 end

        room.banker_seat = player.seat_index
        player.seat.last_chu = {
            pokers_type = pokers_type,
            pokers_point = pokers_point,
            pokers = pokers
        }
    end

    kill_timer(Return, room.roomid, protocol.game_action_chupai, player.seat.action_seq)

    local game_end = helper_check_game_over(player.seat) 
    local content = nil
    if game_end then
        add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_chupai, pokers = pokers, act_pokers_type = pokers_type}))

        if player.seat.mingpai > 0 then
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type}
        else
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type}
        end
        broadcast_packet_except(Return,
                room.seats,
                pack_protocol("sc_game_action_notify", content),
                player.pid
                )
    else
        add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_chupai, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq, pokers = player.seat.hand_seq}}))

        if player.seat.mingpai > 0 then
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq, pokers = player.seat.hand_seq}}
        else
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq}}
        end
        broadcast_packet_except(Return,
                room.seats,
                pack_protocol("sc_game_action_notify", content),
                player.pid
                )
    end

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_chupai,
        act_seat_index = player.seat_index,
        hand_seq = player.seat.hand_seq,
        chued_pokers = pokers,
        chued_pokers_type = pokers_type
    }
    table.insert(room.game_log.log.gameing, record_game_action)

    if game_end then
        game_over(Return, room, player.seat_index)
    else
        room.waiting_actions[room.curr_turn] = nil
        set_next_turn(room)
        helper_game_start_chupai(Return, room)
    end

    return pack_return(Return)
end

function helper_check_game_over(seat)
    if #seat.hand_seq == 0 then
        return true
    else
        return false
    end
end

function game_over(Return, room, seat_index)
    room.waiting_actions = nil
    room.status = room_game_over
    room.jdz_liuju = 0

    local beishu = pokers_module.get_dizhu_pokers_beishu(room) * room.beishu

    local dizhu_win = room.dizhu_seat == seat_index and true or false
    local end_game = {seq_infos = {}, beishu = 1}
    local chuntian = true
    local remain_count = 0
    local seat_beishu = {1, 1, 1}

    if dizhu_win then
        for i, v in ipairs(room.seats) do
            if i ~= room.dizhu_seat and #v.hand_seq > 0 then
                if v.chued_count > 0 then chuntian = false end
                if remain_count == 0 then remain_count = #v.hand_seq end
                if remain_count > #v.hand_seq then remain_count = #v.hand_seq end
            end
        end
    else
        if room.seats[room.dizhu_seat].chued_count > 1 then
            chuntian = false
        end
        remain_count = #room.seats[room.dizhu_seat].hand_seq
    end

    if chuntian then beishu = beishu * 2 end
    if remain_count > 6 then
        if remain_count <= 12 then
            beishu = beishu * 2
        else
            beishu = beishu * 3
        end
    end

    local mingpai_beishu = 1
    local seat_beishu = {1, 1, 1}
    local jiabei_beishu = {1, 1, 1}
    local gold_change = {0, 0, 0}
    local nongmin_seats = {}
    for i, v in ipairs(room.seats) do
        local lbeishu = 1
        if v.jiabei == 1 then       --加倍
            lbeishu = lbeishu * 2
        elseif v.jiabei == 2 then   --超级加倍
            lbeishu = lbeishu * 4
        end

        if v.mingpai > mingpai_beishu then mingpai_beishu = v.mingpai end 
        jiabei_beishu[i] = lbeishu

        if i ~= room.dizhu_seat then table.insert(nongmin_seats, i) end
    end

    beishu = beishu * mingpai_beishu

    local dizhu_beishu = jiabei_beishu[room.dizhu_seat]
    seat_beishu[room.dizhu_seat] = beishu * dizhu_beishu * (jiabei_beishu[nongmin_seats[1]] + jiabei_beishu[nongmin_seats[2]])
    seat_beishu[nongmin_seats[1]] = beishu * dizhu_beishu * jiabei_beishu[nongmin_seats[1]]
    seat_beishu[nongmin_seats[2]] = beishu * dizhu_beishu * jiabei_beishu[nongmin_seats[2]]
    gold_change[room.dizhu_seat] = seat_beishu[room.dizhu_seat] -- * difen
    gold_change[nongmin_seats[1]] = seat_beishu[nongmin_seats[1]] -- * difen
    gold_change[nongmin_seats[2]] = seat_beishu[nongmin_seats[2]] -- * difen

    if dizhu_win then
        if room.seats[nongmin_seats[1]].player.gold < gold_change[nongmin_seats[1]] then
            gold_change[nongmin_seats[1]] = room.seats[nongmin_seats[1]].player.gold
        end

        if room.seats[nongmin_seats[2]].player.gold < gold_change[nongmin_seats[2]] then
            gold_change[nongmin_seats[2]] = room.seats[nongmin_seats[2]].player.gold
        end

        gold_change[room.dizhu_seat] = gold_change[nongmin_seats[1]] + gold_change[nongmin_seats[2]]

        gold_change[nongmin_seats[1]] = 0 - gold_change[nongmin_seats[1]]
        gold_change[nongmin_seats[2]] = 0 - gold_change[nongmin_seats[2]]
    else
        if room.seats[room.dizhu_seat].player.gold < (gold_change[nongmin_seats[1]] + gold_change[nongmin_seats[2]]) then
            gold_change[nongmin_seats[1]] = math.floor(seat_beishu[nongmin_seats[1]] * gold_change[room.dizhu_seat] / seat_beishu[room.dizhu_seat])
            gold_change[nongmin_seats[2]] = math.floor(seat_beishu[nongmin_seats[2]] * gold_change[room.dizhu_seat] / seat_beishu[room.dizhu_seat])
        end
        gold_change[room.dizhu_seat] = 0 - gold_change[room.dizhu_seat]
    end

    local players_pid = {}
    for i, v in ipairs(room.seats) do
        local left_pokers = nil
        if #v.hand_seq > 0 then
            left_pokers = v.hand_seq
            --table.insert(end_game.seq_infos, {seat_index = i, pokers = v.hand_seq, beishu = 1, money_change = 1})
        end 

        table.insert(end_game.seq_infos, {seat_index = i, pokers = left_pokers, beishu = seat_beishu[i], money_change = gold_change[i]})

        v.player.gold = v.player.gold + gold_change[i]
        table.insert(Return, {"update_user_info", {pid=v.player.pid, gold=v.player.gold}})
        table.insert(players_pid, v.player.pid)
    end

    table.insert(Return, {"write_user_info", players_pid})
    --end_game.beishu = beishu
    local packet_bin = pack_protocol("sc_end_game", end_game)
    broadcast_packet(Return, room, packet_bin)
--local file = io.open('/root/log.txt', 'a')
--io.output(file)
--io.write(_G.print_r(room.game_log))
--io.close(file)
    room.game_log.log.end_info = {
        {beishu = 1, gold = -1},
        {beishu = 1, gold = -1},
        {beishu = 2, gold = 2},
    }

    --add_game_log(Return, room)

    restart_room(room)
end

function set_next_turn(room)
    room.curr_turn = get_next_seat_index(room, room.curr_turn)
end

function set_turn_waiting_action(room, action_id)
    if room.curr_turn < 1 or room.curr_turn > #room.seats then return end
    room.waiting_actions = {}
    room.waiting_actions[room.curr_turn] = {action_id = action_id}
end

function set_turn_timer(Return, room, timerid)
    room.timeout_info = {start_time = os.time(), timeout = room_timer[timerid].time}
    local time = room.seats[room.curr_turn].auto and 1 or room_timer[timerid].time
    add_timer(Return, room.roomid, timerid, time, room.seats[room.curr_turn].action_seq)
end

function kill_turn_timer(Return, room, timerid)
    kill_timer(Return, room.roomid, timerid, room.seats[room.curr_turn].action_seq)
end

function get_next_seat_index(room, seat_index)
    if seat_index < #room.seats then
        return seat_index + 1
    else
        return 1
    end
end

function set_room_dizhu(room, seat_index)
    if room.dizhu_seat == 0 then
        room.dizhu_seat = seat_index
        for i, v in ipairs(room.dizhu_pokers) do
            table.insert(room.seats[seat_index].hand_seq, v)
        end
    end
end

function send_action_failed(Return, pid, action_id)
    add_send(Return, pid, pack_protocol("sc_game_action_failed", {id = action_id}))
end

function broadcast_dizhu_info(Return, room)
    local dizhu = room.seats[room.dizhu_seat]
    local dizhu_packet = {
        dizhu_seat = room.dizhu_seat,
        dizhu_pokers = room.dizhu_pokers,
        hand_seq = {
            count = #dizhu.hand_seq,
            pokers = dizhu.hand_seq
        }
    }
    if dizhu.mingpai > 0 then
        broadcast_packet(Return, room, pack_protocol("sc_dizhu_info", dizhu_packet))
    else
        add_send(Return, dizhu.player.pid, pack_protocol("sc_dizhu_info", dizhu_packet))

        local content = {
            dizhu_seat = room.dizhu_seat,
            dizhu_pokers = room.dizhu_pokers,
            hand_seq = {
                count = #dizhu.hand_seq
            }
        }
        broadcast_packet_except(Return,
        room.seats,
        pack_protocol("sc_dizhu_info", content),
        dizhu.player.pid)
    end

    local record_game_action = {
        msg_type = "record_dizhu_info",
        seat_index = room.dizhu_seat,
        dizhu_pokers = room.dizhu_pokers
    }
    table.insert(room.game_log.log.gameing, record_game_action)
end

function on_cs_add_bot()
    local Return = {}
    add_bot(Return, 'classic_ddz')
    return Return
end

function on_cs_game_debug_time()

end

function on_cs_dismiss_room()

end

function on_cs_gift_action()

end

function on_cs_use_prop(player, packet)
    local room = player.room
    if room == nil or room.status == room_game_over then return end

    local Return = {}

    add_send(Return, dizhu.player.pid, pack_protocol("sc_use_prop", {
        result = true,
        prop_id = packet.prop_id,
        remain_count = 100
    }))

    return pack_return(Return)
end

function on_timer(roomid, TimerID, seq)
    print("on_timer, roomid:",roomid,", TimerID:", TimerID)
    local room = global_rooms[roomid]
    local handler = global_game_timeout_handlers[TimerID]

    if handler ~= nil and room ~= nil then
        local Return = {}
        handler(Return, room, seq)
        return pack_return(Return)
    end
end

function on_game_timeout_mingpai(Return, room, seq)
    if room.status ~= room_sendpokers then return end
    room.waiting_actions = nil
    helper_game_start_jdz(Return, room)
end

function on_game_timeout_jdz(Return, room, seq)
    if room.status ~= room_jiaodizhu then return end
    if seq ~= room.seats[room.curr_turn].action_seq then return end
    if room.waiting_actions[room.curr_turn] == nil or room.waiting_actions[room.curr_turn].action_id[1] ~= protocol.game_action_jdz then return end

    local player = room.seats[room.curr_turn].player
    room.waiting_actions[room.curr_turn] = nil

    room.seats[room.curr_turn].jdz = 0

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_jdz,
        act_seat_index = player.seat_index,
        reply = 0
    }
    table.insert(room.game_log.log.gameing, record_game_action)
    
    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_jdz, act_reply = 0}))
    local content = {act_id = protocol.game_action_jdz, act_reply = 0, act_seat_index = room.curr_turn}
    broadcast_packet_except(Return,
            room.seats,
            pack_protocol("sc_game_action_notify", content),
            player.pid
        )

    if player.seat.auto == false then 
        make_player_auto(Return, player)
    end

    local next_seat = get_next_seat_index(room, player.seat_index)
    if room.seats[next_seat].jdz == -1 then
        set_next_turn(room)
        helper_game_start_jdz(Return, room)
    else
        reset_seats_status(room)
        helper_game_start(room, Return)
    end
end

function on_game_timeout_qdz(Return, room, seq)
    if room.status ~= room_qiangdizhu then return end
    if seq ~= room.seats[room.curr_turn].action_seq then return end

    local seat_index = room.curr_turn
    if room.waiting_actions[seat_index] == nil or room.waiting_actions[seat_index].action_id[1] ~= protocol.game_action_qdz then return end
    --room.seats[seat_index].qdz = 0
    room.waiting_actions[room.curr_turn] = nil

    local player = room.seats[room.curr_turn].player

    add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_qdz, act_reply = 0}))
    local content = {act_id = protocol.game_action_qdz, act_reply = 0, act_seat_index = seat_index}
    broadcast_packet_except(Return,
            room.seats,
            pack_protocol("sc_game_action_notify", content),
            player.pid
        )

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_qdz,
        act_seat_index = player.seat_index,
        reply = 0
    }
    table.insert(room.game_log.log.gameing, record_game_action)
    
    if player.seat.auto == false then 
        make_player_auto(Return, player)
    end

    if player.seat.jdz == 1 then
        local qdz_seats = {}
        for i = 1, 2 do
            local seat = player.seat_index + i
            if seat > #room.seats then seat = seat - #room.seats end
            if room.seats[seat].qdz == 1 then table.insert(qdz_seats, seat) end
        end

        room.curr_turn = qdz_seats[1]
        if #qdz_seats == 1 then
            set_room_dizhu(room, qdz_seats[1])
            broadcast_dizhu_info(Return, room)
            helper_game_start_jiabei(Return, room)
        elseif #qdz_seats == 2 then
            helper_game_start_qdz(Return, room)
        end

        player.seat.qdz = 0
            
        return
    end

    if player.seat.qdz == 1 then
        for i, v in ipairs(room.seats) do
            if i ~= player.seat_index and v.qdz == 1 then
                room.curr_turn = i
                set_room_dizhu(room, i)
                break
            end
        end
        broadcast_dizhu_info(Return, room)
        helper_game_start_jiabei(Return, room)

        return
    end

    local jdz_seat = 0
    local next_qdz_seat = 0
    local qdz_seat = 0
    for i, v in ipairs(room.seats) do
        if i ~= player.seat_index and v.jdz == -1 and v.qdz == -1 then
            next_qdz_seat = i
        end

        if i ~= player.seat_index and v.jdz == -1 and v.qdz == 1 then
            qdz_seat = i
        end

        if v.jdz == 1 then
            jdz_seat = i
         end
    end

    if next_qdz_seat ~= 0 then
        player.seat.qdz = 0
        room.curr_turn = next_qdz_seat
        --set_turn_waiting_action(room, {protocol.game_action_qdz})
        helper_game_start_qdz(Return, room)

        return
    end

    if next_qdz_seat == 0 and qdz_seat == 0 then
        room.curr_turn = jdz_seat
        set_room_dizhu(room, jdz_seat)
        broadcast_dizhu_info(Return, room)
        helper_game_start_jiabei(Return, room)
    else
        set_next_turn(room)
        helper_game_start_qdz(Return, room)
    end

    room.seats[seat_index].qdz = 0
end

function on_game_timeout_jiabei(Return, room, seq)
    if room.status ~= room_jiabei then return end
    room.waiting_actions = nil
    
    for i, v in ipairs(room.seats) do
        if v.jiabei == -1 then
            v.jiabei = 0
            add_send(Return, v.player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_jiabei, act_reply = 0}))
            local content = {act_id = protocol.game_action_jiabei, act_reply = 0, act_seat_index = i}
            broadcast_packet_except(Return,
               room.seats,
               pack_protocol("sc_game_action_notify", content),
               v.player.pid
              )

            if v.auto == false then 
            --    make_player_auto(Return, v.player)
            end

            local record_game_action = {
                msg_type = "record_game_action",
                id = protocol.game_action_jiabei,
                act_seat_index = i,
                reply = 0
            }
            table.insert(room.game_log.log.gameing, record_game_action)
        end
    end

    helper_game_start_chupai(Return, room)
end

function on_game_timeout_chupai(Return, room, seq)
    if room.status ~= room_gaming then return end
    if room.seats[room.curr_turn].action_seq ~= seq then return end
    if room.waiting_actions[room.curr_turn] == nil or room.waiting_actions[room.curr_turn].action_id[1] ~= protocol.game_action_chupai then return end
    room.waiting_actions = {}
    local player = room.seats[room.curr_turn].player

    local pokers = nil
    local pokers_type = 0
    local pokers_point = 0
    local seat = room.seats[room.curr_turn]
    if seat.auto then
        pokers = pokers_module.get_auto_action_pokers(room)
        if #pokers > 0 then
            pokers_type, pokers_point = pokers_module.pokers_type_check(pokers)
            local remove_result = pokers_module.remove_hand_seq_pokers(room.seats[room.curr_turn], pokers)
            assert(remove_result)
            room.banker_seat = player.seat_index
        else
            pokers = nil
        end
    else
        if room.curr_turn == room.banker_seat or room.banker_seat == 0 then
            local poker = pokers_module.get_default_poker(room)
            pokers = {poker}
            pokers_type, pokers_point = pokers_module.pokers_type_check(pokers)
            local remove_result = pokers_module.remove_hand_seq_pokers(room.seats[room.curr_turn], pokers)
            assert(remove_result)
            if room.banker_seat == 0 then room.banker_seat = player.seat_index end
        end
    end

    room.seats[room.curr_turn].last_chu = {
        pokers_type = pokers_type,
        pokers_point = pokers_point,
        pokers = pokers
    }

    local record_game_action = {
        msg_type = "record_game_action",
        id = protocol.game_action_chupai,
        act_seat_index = player.seat_index,
        hand_seq = player.seat.hand_seq,
        chued_pokers = pokers,
        chued_pokers_type = pokers_type
    }
    table.insert(room.game_log.log.gameing, record_game_action)

    local game_end = helper_check_game_over(player.seat)
    local content = nil
    if game_end then
        add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_chupai, pokers = pokers, next_turn = pokers_point, act_pokers_type = pokers_type}))

        if player.seat.mingpai > 0 then
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point}
        else
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point}
        end
        broadcast_packet_except(Return,
                room.seats,
                pack_protocol("sc_game_action_notify", content),
                player.pid
                )
    else
        add_send(Return, player.pid, pack_protocol("sc_game_action", {act_id = protocol.game_action_chupai, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq, pokers = player.seat.hand_seq}}))

        if player.seat.mingpai > 0 then
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq, pokers = player.seat.hand_seq}}
        else
            content = {act_id = protocol.game_action_chupai, act_seat_index = player.seat_index, pokers = pokers, act_pokers_type = pokers_type, next_turn = pokers_point, acted_hand_seq = {count = #player.seat.hand_seq}}
        end
        broadcast_packet_except(Return,
                room.seats,
                pack_protocol("sc_game_action_notify", content),
                player.pid
                )
    end

    if game_end then
        game_over(Return, room, player.seat_index)
    else
        if player.seat.auto == false then 
            make_player_auto(Return, player)
        end
        room.waiting_actions[room.curr_turn] = nil
        set_next_turn(room)
        helper_game_start_chupai(Return, room)
    end
end

function make_player_auto(Return, player)
    local room = player.room
    local seat = player.seat

    seat.auto = true

    add_send(Return, player.pid, pack_protocol("sc_game_auto",
    {
        auto = true
    })
    )

    broadcast_packet_except(Return, room, pack_protocol("sc_game_auto_notify",
    {
        seat_index = seat.index,
        auto = true
    }),
    player.pid)
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

function add_timer(Return, roomid, timerid, time, seq)
if timerid ~= 5 then
    table.insert(Return, {'start_timer', {roomid, timerid, time, seq}})
end
end

function kill_timer(Return, roomid, timerid, seq)
    table.insert(Return, {'kill_timer', {roomid, timerid, seq}})
end

function change_player_info(Return, data_map)
    table.insert(Return, {"update_user_info", data_map})
end

function update_user_db_data(Return, users_pid)
    table.insert(Return, {"write_user_info", users_pid})
end

function kick_gold_not_enough_player(Return, room)
	if room.status == room_game_over then
		for i, v in ipairs(room.seats) do
			if (v ~= none and (v.player.gold < room.place_config.fuck_gold)) then
				if DEBUG then print('-----kick gold not enough player------------------------------') end
				make_player_leave(Return, v.player, 'error_game_player_money_not_enough_for_place')
			end
		end
	end
end

function kick_offline_player(Return, room)
	if room.status == room_game_over then
		for i, v in ipairs(room.seats) do
			if (v ~= none and (not v.player.online) ) then
				make_player_leave(Return, v.player, 'kick_offline_player')
			end
		end
	end

end


register_packet_handler()
register_game_action_handler()
register_game_timeout_handler()
