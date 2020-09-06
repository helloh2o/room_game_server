
´V
gameserver.proto
gameserver"Q
room_action
id (Rid
from (	Rfrom

playerJson (	R
playerJson"
Test
id (Rid"4
protocol
id (Rid
content (Rcontent"L
sc_protocol_pack
id (Rid(
pack (2.gameserver.protocolRpack"
	heartbeat"#
sc_game_debug
info (	Rinfo"√

st_hu_desc
type1 (Rtype1
type2 (Rtype2
gen (Rgen
self_mo (RselfMo
fan (Rfan
types (Rtypes
order (Rorder 
give_hu_seat (R
giveHuSeat"Ö
scgame_show_actions
id (Rid
sub_id (RsubId
tile_seq (BRtileSeq(
acted_seat_index (RactedSeatIndex"
sc_game_hide_actions"÷
stplayer_info
oid (Roid
id (	Rid
idtype (	Ridtype
	nick_name (	RnickName
	room_card (RroomCard
gold (Rgold
sex (Rsex
portrait (	Rportrait
ip	 (	Rip
location
 (	Rlocation
exp (Rexp
online (Ronline
	auto_play (RautoPlay
	signature (	R	signature"?
st_hand_seq
count (Rcount
pokers (BRpokers"ö
scenter_seat_info:
player_info (2.gameserver.stplayer_infoR
playerInfo
ready (Rready

seat_index (R	seatIndex
money (Rmoney"Ô
sccontinue_seat_info

seat_index (R	seatIndex:
player_info (2.gameserver.stplayer_infoR
playerInfo
ready (Rready
lack (Rlack
is_hu (RisHu
hu_seq (RhuSeq$
hand_seq_count (RhandSeqCount
mo_count (RmoCount2
hand_seq	 (2.gameserver.st_hand_seqRhandSeq;
complex_seq
 (2.gameserver.sccomplex_tileR
complexSeq
	chued_seq (RchuedSeq/
hu_desc (2.gameserver.st_hu_descRhuDesc

is_baojiao (R	isBaojiao
money (Rmoney
sure_action (R
sureAction
piao (Rpiao
bai_pai (RbaiPai#
bai_pai_hu_seq (RbaiPaiHuSeq"
cs_ready_game"!
cs_leave_room
why (	Rwhy"8
cs_game_action
id (Rid
pokers (Rpokers"A
st_lack_info

seat_index (R	seatIndex
lack (Rlack"?
sc_lack_infos.
infos (2.gameserver.st_lack_infoRinfos"J
st_dismiss_info

seat_index (R	seatIndex
dismiss (Rdismiss"≈
sc_continue_game
banker_seat (R
bankerSeat

seat_index (R	seatIndex
lack_second (R
lackSecond
	curr_turn (RcurrTurn
turn_second (R
turnSecond
thinking (Rthinking!
think_second (RthinkSecondB
show_actions (2.gameserver.scgame_show_actionsRshowActionsA
seat_infoes	 (2 .gameserver.sccontinue_seat_infoR
seatInfoes!
tiles_remain
 (RtilesRemain
roomid (Rroomid
	room_base (RroomBase
room_pwd (	RroomPwd#
current_round (RcurrentRound
game_config (	R
gameConfig
gametype (	Rgametype
place (	Rplace

owner_seat (R	ownerSeatA
exchange_info (2.gameserver.sc_exchange_infoRexchangeInfo#
dismiss_apply (RdismissApply%
dismiss_second (RdismissSecond>
dismiss_info (2.gameserver.st_dismiss_infoRdismissInfo1
last_chued_seat_index (RlastChuedSeatIndex

creater_id (R	createrId!
creater_type (	RcreaterType"B
sc_enter_room_failed
reason (Rreason
desc (	Rdesc"Á
sc_enter_room

seat_index (R	seatIndex>
seat_infoes (2.gameserver.scenter_seat_infoR
seatInfoes
roomid (Rroomid
	room_base (RroomBase
game_config (	R
gameConfig
gametype	 (	Rgametype
place
 (	Rplace
room_pwd (	RroomPwd#
current_round (RcurrentRound

owner_seat (R	ownerSeat

creater_id (R	createrId!
creater_type (	RcreaterType#
dismiss_apply (RdismissApply%
dismiss_second (RdismissSecond>
dismiss_info (2.gameserver.st_dismiss_infoRdismissInfoB
show_actions (2.gameserver.scgame_show_actionsRshowActions"R
sc_enter_room_notify:
	seat_info (2.gameserver.scenter_seat_infoRseatInfo".
sc_ready_game_failed
reason (Rreason"
sc_ready_game"5
sc_ready_game_notify

seat_index (R	seatIndex".
sc_leave_room_failed
reason (Rreason"Q
sc_leave_room
result (Rresult
reason (Rreason
why (	Rwhy"5
sc_leave_room_notify

seat_index (R	seatIndex"a
sccomplex_tile
type (Rtype
id (Rid
ids (Rids
sub_type (RsubType"©
all_seq_info

seat_index (R	seatIndex=
wan_gang_mt (2.gameserver.st_money_transferR	wanGangMt=
zhi_gang_mt (2.gameserver.st_money_transferR	zhiGangMt;

an_gang_mt (2.gameserver.st_money_transferRanGangMt2
hu_mt (2.gameserver.st_money_transferRhuMt;

hua_zhu_mt (2.gameserver.st_money_transferRhuaZhuMt;

da_jiao_mt (2.gameserver.st_money_transferRdaJiaoMt8
da_jiao_desc (2.gameserver.st_hu_descR
daJiaoDesc/
hu_desc	 (2.gameserver.st_hu_descRhuDesc2
hand_seq
 (2.gameserver.st_hand_seqRhandSeq
hu_seq (RhuSeq;
complex_seq (2.gameserver.sccomplex_tileR
complexSeq

total_gold (R	totalGold!
money_change (RmoneyChange:
	maipai_mt (2.gameserver.st_money_transferRmaipaiMt
bai_pai (RbaiPai
piao (Rpiao;

bai_pai_mt (2.gameserver.st_money_transferRbaiPaiMt6
piao_mt (2.gameserver.st_money_transferRpiaoMt"^
one_ju_seq_info5
	seq_infos (2.gameserver.all_seq_infoRseqInfos
liuju (Rliuju"À
sc_end_game5
	seq_infos (2.gameserver.all_seq_infoRseqInfos
liuju (Rliuju#
current_round (RcurrentRound
total_round (R
totalRound)
is_game_group_end (RisGameGroupEnd"Æ
sc_end_game_groupA
game_seq_infos (2.gameserver.one_ju_seq_infoRgameSeqInfos!
consume_card (RconsumeCard3
first_round_start_time (RfirstRoundStartTime"|
sc_game_action_failed
id (Rid
sub_id (RsubId
reason (Rreason$
remove_tile_id (RremoveTileId"™
sc_game_refresh_hand_seq
	action_id (RactionId9
act_hand_seq (2.gameserver.st_hand_seqR
actHandSeqB
act_complex_seq (2.gameserver.sccomplex_tileRactComplexSeq&
act_chued_seq (BRactChuedSeq1
last_chued_seat_index (RlastChuedSeatIndex
bai_pai (RbaiPai"ê
st_money_transfer
person (Rperson
atm (Ratm
money (Rmoney
transfer (Rtransfer
gang_status (R
gangStatus"Ó
sc_game_action
id (Rid
sub_id (RsubIdD
money_transfer (2.gameserver.st_money_transferRmoneyTransfer%
tile_type_or_id (RtileTypeOrId$
act_seat_index (RactSeatIndex9
act_hand_seq (2.gameserver.st_hand_seqR
actHandSeq 

act_hu_seq (BRactHuSeqB
act_complex_seq (2.gameserver.sccomplex_tileRactComplexSeq&
act_chued_seq	 (BRactChuedSeq(
acted_seat_index
 (RactedSeatIndexB
show_actions (2.gameserver.scgame_show_actionsRshowActions!
tiles_remain (RtilesRemain/
hu_desc (2.gameserver.st_hu_descRhuDesc
bai_pai (RbaiPai"°
sc_game_action_notify
id (Rid
sub_id (RsubIdD
money_transfer (2.gameserver.st_money_transferRmoneyTransfer%
tile_type_or_id (RtileTypeOrId$
act_seat_index (RactSeatIndex+
act_hand_seq_count (RactHandSeqCount 
act_mo_count (R
actMoCount9
act_hand_seq (2.gameserver.st_hand_seqR
actHandSeqB
act_complex_seq	 (2.gameserver.sccomplex_tileRactComplexSeq&
act_chued_seq
 (BRactChuedSeq

act_hu_seq (RactHuSeq(
acted_seat_index (RactedSeatIndex!
tiles_remain (RtilesRemain/
hu_desc (2.gameserver.st_hu_descRhuDesc
bai_pai (RbaiPai#
bai_pai_hu_seq (RbaiPaiHuSeq"b
hand_seq_info

seat_index (R	seatIndex2
hand_seq (2.gameserver.st_hand_seqRhandSeq"Œ
sc_start_game<
other_infoes (2.gameserver.hand_seq_infoRotherInfoes;
you_seq_info (2.gameserver.hand_seq_infoR
youSeqInfo!
tiles_remain (RtilesRemain
banker_seat (R
bankerSeat"t
sc_game_show_actions
timeout (RtimeoutB
show_actions (2.gameserver.scgame_show_actionsRshowActions"(
sc_sure_lack
timeout (Rtimeout"*
sc_ready_timer
timeout (Rtimeout"‹
sc_game_turn
timeout (Rtimeout

seat_index (R	seatIndex
mo (Rmo

mo_tile_id (RmoTileId!
tiles_remain (RtilesRemainB
show_actions (2.gameserver.scgame_show_actionsRshowActions"ü
sc_game_turn_notify
timeout (Rtimeout

seat_index (R	seatIndex
mo (Rmo

mo_tile_id (RmoTileId!
tiles_remain (RtilesRemain" 
sc_broadcast
msg (	Rmsg",
sc_sure_exchange
timeout (Rtimeout"˙
sc_exchange_info!
exchange_out (RexchangeOut
exchange_in (R
exchangeIn
maipai (Rmaipai#
exchange_type (RexchangeType;
you_seq_info (2.gameserver.hand_seq_infoR
youSeqInfo(
exchange_in_seat (RexchangeInSeat"î
sc_exchange_tiles_response
result (Rresult;
you_seq_info (2.gameserver.hand_seq_infoR
youSeqInfo!
exchange_out (RexchangeOut"i
sc_gift_action
	send_seat (RsendSeat!
receive_seat (RreceiveSeat
gift_id (RgiftId"+
sc_seat_voiceid
voiceid (Rvoiceid"µ
scseat_end_group_info
zi_mo_times (R	ziMoTimes"
jie_pao_times (RjiePaoTimes$
dian_pao_times (RdianPaoTimes"
an_gang_times (RanGangTimes&
ming_gang_times (RmingGangTimes
total_score (R
totalScore!
consume_card (RconsumeCard"
is_big_winner (RisBigWinner"W
sc_end_group_infoB
seat_infoes (2!.gameserver.scseat_end_group_infoR
seatInfoes"(
sc_sure_piao
timeout (Rtimeout"5
sc_piao_infos$
seat_piao_info (RseatPiaoInfo"h
seat_gps_info

seat_index (R	seatIndex

coordinate (	R
coordinate
address (	Raddress"L
sc_room_gps_info8

gps_infoes (2.gameserver.seat_gps_infoR	gpsInfoes"%
cs_inspect_player
oid (Roid"B
sc_inspect_player
oid (Roid
	nick_name (	RnickName"%
cs_dismiss_room
type (Rtype"9
sc_dismiss_room
type (Rtype
time (Rtime"K
sc_dismiss_room_result
result (Rresult
op_seats (RopSeats"_
sc_dismiss_room_notify

seat_index (R	seatIndex
type (Rtype
time (Rtime"
sc_qian_si_end"A
sc_sure_action
seat (Rseat
	action_id (RactionId""

cs_add_bot
count (Rcount"
cs_debug_dismiss_room"
cs_debug_run_action"
cs_game_auto""
sc_game_auto
auto (Rauto"H
sc_game_auto_notify

seat_index (R	seatIndex
auto (Rauto"
cs_game_manual"
cs_resend_action"*
cs_change_online
online (Ronline"
cs_match_game"
cs_ready_match_game"
sc_enter_match_room"
cs_game_refresh_seq"U
cs_chat

seat_index (R	seatIndex
msg (	Rmsg
msg_type (RmsgType"I
sc_change_online

seat_index (R	seatIndex
online (Ronline"L
cs_gift_action!
receive_seat (RreceiveSeat
gift_id (RgiftId"-
cs_submit_voiceid
voiceid (Rvoiceid"G
cs_seat_gps

coordinate (	R
coordinate
address (	Raddressbproto3