package ai

var (
	sc_enter_room_failed = 0x1100
	sc_enter_room        = 0x1101
	sc_enter_room_notify = 0x1102

	sc_ready_game_failed = 0x1103
	sc_ready_game        = 0x1104
	sc_ready_game_notify = 0x1105

	sc_leave_room_failed = 0x1106
	sc_leave_room        = 0x1107
	sc_leave_room_notify = 0x1108

	sc_game_action        = 0x1109
	sc_game_action_notify = 0x110A

	sc_start_game = 0x110B

	sc_game_show_actions = 0x110C

	sc_sure_lack = 0x110D

	sc_game_turn = 0x110E

	sc_game_turn_notify = 0x110F

	sc_continue_game = 0x1110

	sc_inspect_player = 0x1112

	sc_game_action_failed = 0x1113

	sc_end_game = 0x1114

	sc_game_hide_actions = 0x1115

	sc_ready_timer = 0x111A

	sc_lack_infos = 0x111B

	sc_enter_match_room = 0x111C

	sc_broadcast = 0x111D

	sc_sure_exchange = 0x1120
	sc_exchange_info = 0x1121

	sc_dismiss_room        = 0x1122
	sc_dismiss_room_notify = 0x1123
	sc_dismiss_room_result = 0x1124

	sc_protocol_pack = 0x11FE
	sc_game_debug    = 0x11FF

	sc_change_online = 0x1200

	sc_game_refresh_hand_seq = 0x1201

	sc_exchange_tiles_response = 0x1202

	sc_gift_action = 0x1203

	sc_end_game_group = 0x1204

	sc_seat_voiceid = 0x1205

	sc_qian_si_end = 0x1206

	sc_end_group_info = 0x1207

	sc_sure_action = 0x1208

	sc_game_auto_notify = 0x1209
	sc_sure_piao        = 0x1210
	sc_piao_infos       = 0x1211

	sc_room_gps_info = 0x1212

	sc_dizhu_info = 0x1213
	sc_use_prop   = 0x1214
	//--------------------------------------------------CS----------------------------------------------------------

	cs_ready_game  = 0x2100
	cs_leave_room  = 0x2101
	cs_game_action = 0x2102

	cs_inspect_player = 0x2104

	cs_add_bot     = 0x2105
	cs_game_auto   = 0x2106
	cs_game_manual = 0x2107

	cs_resend_action = 0x2108

	cs_chat = 0x2109

	cs_match_game       = 0x210A
	cs_ready_match_game = 0x210B
	cs_change_online    = 0x210C

	cs_debug_dismiss_room = 0x210D
	cs_debug_run_action   = 0x210E

	cs_dismiss_room = 0x2111

	cs_gift_action    = 0x2112
	cs_submit_voiceid = 0x2113

	cs_game_refresh_seq = 0x2114

	cs_seat_gps = 0x2115

	cs_use_prop = 0x2116

	heartbeat = 0x00FF
)
