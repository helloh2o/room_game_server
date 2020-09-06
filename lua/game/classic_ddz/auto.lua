module("auto", package.seeall)

local protobuf = require "protobuf"
local protocol = require "protocol"
local pokers = require('pokers')


auto_packet_handlers = {}
auto_game_action_handlers = {}


function on_auto_packet_game_turn(player, packet, Return, is_resent)
    local room = player.room
    local seat = player.seat

    local show_actions = packet.show_actions
    local hand_seq = seat.hand_seq
    local wang_count = 0
    local er_count = 0
    local little_seq = 0
    local little_seq_point = 0
    for i, v in ipairs(hand_seq) do
        local _point = pokers.get_poker_point(v)
        
        if little_seq_point == 0 or _point < little_seq_point then 
            little_seq = v
            little_seq_point = _point 
        end

        if v > 0x50 then wang_count = wang_count + 1 end
        if _point == 0x0F then er_count = er_count + 1 end
    end

    table.sort(seq_points, function(a, b) return a.point < b.point end)

    if show_actions[1] == protocol.game_action_jdz then
        local jdz = 0
        if wang_count > 0 and er_count > 0 then
            jdz = 1
        end

        auto_add_send_bin(Return, auto_pack_protocol("cs_game_action",
        player.pid,
         {
             id = protocol.game_action_jdz,
             reply = jdz 
         }))
    elseif show_actions[1] == protocol.game_action_qdz then
        local qdz = 0
        if wang_count > 0 and er_count > 1 then
            qdz = 1
        end

        auto_add_send_bin(Return, auto_pack_protocol("cs_game_action",
        player.pid,
         {
             id = protocol.game_action_qdz,
             reply = qdz 
         }))
    elseif show_actions[1] == protocol.game_action_chupai then
        local pokers = {}
        if (#hand_seq == 20) or (player.seat_index == room.banker_seat) then
            pokers = {little_seq}
        end
        auto_add_send_bin(Return, auto_pack_protocol("cs_game_action",
        player.pid,
         {
             id = protocol.game_action_chupai,
             pokers = pokers 
         }))
    end
end


function on_auto_packet_game_show_actions(player, packet, Return)
    local seat = player.seat
    local room = player.room

    local show_actions = packet.show_actions

    if show_actions[1] == protocol.game_action_jiabei then
        auto_add_send_bin(Return, auto_pack_protocol("cs_game_action",
        player.pid,
         {
             id = protocol.game_action_jiabei,
             reply = 0 
         }))
    end
end

function on_auto_packet_end_game(player, content_lua, Return)

   if (player.idtype == "bot") then
      local packet = auto_pack_protocol("cs_leave_room", player.pid, {why="player 掉线了"})
    
      print('-----------------------------------------------game end ,托管必须leave-------')

      auto_add_send_bin(Return, packet) 
   end
end

function on_auto_packet_game_debug(player, packet, Return)

	print("@@@@@@@@@@@@@@@@@@"..packet.info.."@@@@@@@@@@@@@@"..player.pid)

	--assert(false)
end



function register_auto_packet_handler()
    auto_packet_handlers["sc_game_turn"]             = on_auto_packet_game_turn
    auto_packet_handlers["sc_game_show_actions"]     = on_auto_packet_game_show_actions
    auto_packet_handlers["sc_end_game"]              = on_auto_packet_end_game
	auto_packet_handlers["sc_game_debug"]			 = on_auto_packet_game_debug
end

function register_auto_game_action_handler()
    auto_game_action_handlers[protocol.game_action_guo_tile]         = on_game_game_action_guo_tile
end

function auto_game_on_packet(player, packet_bin, is_resent)

    --unpack packet
    local protocol_id, protocol_content =
       protocol.game_protocol_unpack_bin(packet_bin)

    local Return = {}

    if protocol_id ~= "sc_protocol_pack" then
        local handler = auto_packet_handlers[protocol_id]
			
        if (handler ~= nil) then
            handler(player, protocol_content, Return, is_resent)
        else
            --assert(false)
        end
    else
        for i, v in ipairs(protocol_content.pack) do

            local handler = auto_packet_handlers[protocol.game_id_and_desc[v.id]]

--			print(player.pid..'-----'.. protocol.game_id_and_desc[v.id])

            if (handler ~= nil) then
                handler(player, v.content, Return, is_resent)
            else
                --assert(false)
            end
        end
    end

	    return Return 
end

function cp_room(room)
    return room
end

function auto_add_send_bin(Return, packet)
    table.insert(Return, {'send', packet})
end

function auto_pack_protocol(_id, pid, _content)
    assert(type(_content) == 'table' or _content == nil)

	if (_id == "cs_game_action") then
		print(pid..'------' .. _id ..'_'..protocol.game_action_desc[_content.id])
	else
		print(pid..'------' .. _id)
	end

    if _content == nil then
        return protobuf.encode("gameserver.protocol", 
            {id = protocol.get_id(_id)})
    else
        return protobuf.encode("gameserver.protocol",
            {id = protocol.get_id(_id), content = auto_pack_content("gameserver." .. _id, _content)})
    end
end

function auto_pack_content(desc, t)
    assert(type(t) == 'table')
    return protobuf.encode(desc, t)
end

register_auto_packet_handler()
register_auto_game_action_handler()
