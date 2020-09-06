-- TODO 
-- 1. 加一个游戏一局结束的协议
local sformat = string.format
local protobuf = require "protobuf"
local pencode = protobuf.encode
local pdecode = protobuf.decode

module( "protocol", package.seeall )


game_action_mingpai     = 1
game_action_qdz         = 2
game_action_jiabei      = 3
game_action_chupai      = 4


game_action_desc = 
{
    "game_action_mingpai",
    "game_action_qdz",
    "game_action_jiabei",
	"game_action_chupai"
}

error_id_and_desc = {
    success = 0,
	--common
    error_unknown           = 1,
    error_player_not_exist   = 2,

	-- game error
-- sys
	error_player_in_game	= 100,
	error_player_in_another_node_game = 101,
	-- logic
    error_enter_room_passwd = 150,
    error_enter_room_full   = 151,
    error_can_not_leave_room= 152,
	error_gang_fail_qiang_gang_hu = 153,
    error_player_money_not_enough_for_place = 156,
    error_player_room_card_not_enough_for_place = 157,
    error_player_enter_no_room  = 158,
    error_enter_room_no_owner = 159,
    error_token_no_player = 160,
	error_kickout			= 161,
    error_kickout_2         = 162,

    error_room_dismiss = 111111,
    error_room_crash   = 222222,
}

game_id_and_desc = {
	
	----------------------------------------------------------------------------S2C-------------------------------------------
	sc_enter_room_failed 	= 0x1100, --the first one standby sc or cs, the second standby game hall 
	sc_enter_room			= 0x1101,
	sc_enter_room_notify	= 0x1102,

	sc_ready_game_failed 	= 0x1103,
	sc_ready_game        	= 0x1104,
	sc_ready_game_notify 	= 0x1105,
	
	sc_leave_room_failed    = 0x1106,
	sc_leave_room			= 0x1107,
	sc_leave_room_notify	= 0x1108,

	sc_game_action 			= 0x1109,
	sc_game_action_notify	= 0x110A,

	sc_start_game			= 0x110B,

	sc_game_show_actions	= 0x110C,
    
    sc_sure_lack            = 0x110D,

	sc_game_turn			= 0x110E,

	sc_game_turn_notify		= 0x110F,

    sc_continue_game        = 0x1110,

    sc_inspect_player       = 0x1112,

    sc_game_action_failed   = 0x1113,

    sc_end_game             = 0x1114,

	sc_game_hide_actions	= 0x1115,

	sc_ready_timer			= 0x111A,

    sc_lack_infos           = 0x111B,

    sc_enter_match_room     = 0x111C,

    sc_broadcast            = 0x111D,

	sc_sure_exchange		= 0x1120,
	sc_exchange_info		= 0x1121,

    sc_dismiss_room         = 0x1122,
    sc_dismiss_room_notify  = 0x1123,
    sc_dismiss_room_result  = 0x1124,

    sc_protocol_pack        = 0x11FE,
	sc_game_debug			= 0x11FF,

	sc_change_online	    = 0x1200,
	
    sc_game_refresh_hand_seq= 0x1201,

	sc_exchange_tiles_response	= 0x1202,
    
    sc_gift_action          = 0x1203,

    sc_end_game_group       = 0x1204,

    sc_seat_voiceid         = 0x1205,

    sc_qian_si_end          = 0x1206,

    sc_end_group_info       = 0x1207,

    sc_sure_action          = 0x1208,
	
	sc_game_auto_notify     = 0x1209,
    sc_sure_piao            = 0x1210,
    sc_piao_infos           = 0x1211,
	
	sc_room_gps_info		= 0x1212,


    --------------------------------------------------Golang----------------------------------------------------------
    room_action		    =  0x101,

	--------------------------------------------------CS----------------------------------------------------------
	
	cs_ready_game			= 0x2100,
	cs_leave_room			= 0x2101,
	cs_game_action			= 0x2102,

    cs_inspect_player       = 0x2104,

    cs_add_bot              = 0x2105,
	cs_game_auto			= 0x2106,
	cs_game_manual			= 0x2107,

	cs_resend_action		= 0x2108,

    cs_chat                 = 0x2109,

    cs_match_game           = 0x210A,
    cs_ready_match_game     = 0x210B,
    cs_change_online        = 0x210C,

    cs_debug_dismiss_room   = 0x210D,
    cs_debug_run_action     = 0x210E,

    cs_dismiss_room         = 0x2111,

    cs_gift_action          = 0x2112,
    cs_submit_voiceid       = 0x2113,

    cs_game_refresh_seq     = 0x2114,
	
	cs_seat_gps				= 0x2115,

    heartbeat               = 0x00FF,

}

function v_to_key(t) 
    local tmp = {}
    for k, v in pairs(t) do
        tmp[v] = k
    end
    for k, v in pairs(tmp) do
        t[k] = v
    end
end
v_to_key(game_id_and_desc)
v_to_key(error_id_and_desc)

function test_game_id_and_desc(t)
	for k, v in pairs(t) do
		if (t[v] ~= k) then
			if not NoPrint then print(k .. ' and ' ..v) end
            if not NoPrint then print( string.format( "0x%X", tonumber(v) ) ) end
		end
		assert(t[v] == k)
	end
end

local test_error_id_and_desc = test_game_id_and_desc

test_game_id_and_desc(game_id_and_desc)
test_error_id_and_desc( error_id_and_desc )

--------------------------------------------------------------------------------
get_id_and_pkg = function(k)
    local v = game_id_and_desc[k]
    if v then return v, 'gameserver.' end

    return nil, 'unknownserver.'
end

get_id = function(k)
    local v = game_id_and_desc[k]
    if v then return v end

    return nil
end

function game_protocol_unpack(proto_lua)
    assert( proto_lua, 'proto_lua' )
    assert( proto_lua.id, 'proto_lua id nil' )
    assert( proto_lua.id ~= 0, 'proto_lua id zero' )

    local proto_id_name, pkg = get_id_and_pkg( proto_lua.id )
    local proto_content

    if not proto_id_name then
        if not NoPrint then print( false, "[protocol] unknown proto-id: " .. proto_lua.id ) end
        return
    end

    if proto_lua.content then
        local game_proto_id_name = pkg .. proto_id_name
        proto_content, msg = protobuf.decode(game_proto_id_name, proto_lua.content)
        if (false == proto_content) then print( '\n\n----->protocol error: \n\t' .. tostring(msg) ) end
    end

    return proto_id_name, proto_content
end

local protocol_pack_id = get_id_and_pkg( "sc_protocol_pack" )
function game_protocol_unpack_bin(proto_bin)
    print("begin game_protocol_unpack_bin")
    local proto_lua, msg = protobuf.decode("gameserver.protocol", proto_bin)
    if not proto_lua then
        print( 'pack bin error', msg )
        return
    end
    print("proto_lua.id = ",proto_lua.id)
    local proto_id_name, pkg = get_id_and_pkg( proto_lua.id )
    if not proto_id_name or not pkg then
        if not NoPrint then
            print( 'id or pkg cannot be nil: [id]' .. tostring(proto_lua.id) .. ' [id_name]' .. tostring(proto_id_name) .. ' [pkg]' ..              tostring(pkg) )
        end

        return
    end
    print("proto_id_name = ",proto_id_name)
    local proto_content, msg

    if proto_lua.content then
        local game_proto_id_name = pkg .. proto_id_name
        print("game_proto_id_name = ",game_proto_id_name)
        proto_content, msg = protobuf.decode(game_proto_id_name, proto_lua.content)
        -- print content for test
        for key, value in pairs(proto_content) do
            print(key,value)
        end
    end

    if (proto_lua.id == protocol_pack_id) then

        for i=1, #proto_content.pack do
            local _name, _content = game_protocol_unpack(proto_content.pack[i])
            if _name and _content then
                proto_content.pack[i].content = _content
            end
        end

    end

    return proto_id_name, proto_content, msg
end

