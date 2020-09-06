local protocol 		= require('protocol')
--local game_cfg      = require('game_cfg')

function db_transfer_big_winner_count(caller, Return, room, card_count)
    for k, v in pairs(room.big_winners) do
        print('big_winner minus card:', room.big_winners_consume_card)
        db_minus_room_card(caller, Return, v, room.big_winners_consume_card, 1)
    end
end

function handle_task(Return, caller, oid, task_type, param)   
    --for _, v_task in ipairs(game_cfg.cfg_task) do
    --    if v_task.task_type == task_type then 
                    
    --            db_add_sql_no_check(Return, {[[INSERT into task(user_id, task_id, task_type, stage, state, param1) VALUES($1, $2, $3, $4, 0, $5) on conflict(user_id, task_id) do UPDATE  set param1=task.param1 + $6, last_update_date = now() where task.last_update_date::date = CURRENT_DATE]], 
    --                                                    {oid, v_task.task_id, v_task.task_type, v_task.stage, param, param}})
    --            db_add_sql_no_check(Return, {[[UPDATE  task set state = 0 , param1= $1, last_update_date = now() where user_id = $2 and task_id =$3 and task.last_update_date::date < CURRENT_DATE]], { param, oid, v_task.task_id}})	
    --            db_add_sql_no_check(Return, {[[UPDATE  task set state = 1  where user_id = $1 and task_id = $2 and param1 >= $3 and state != 2]], { oid, v_task.task_id, v_task.require1}})                   
            
    --    end
    --end   
end

-----------------------------------------------金币变化--------------------------------
function db_add_gold(caller, Return, player, gold, reason)
	player.gold = player.gold + gold 
	local room = player.room
	assert(gold >= 0)
	assert(player.gold >= 0)
    local msg = encode_json({msg_type='add_gold', 
                             reason = reason or 0,  --0 service, 1 win, 2 lose 
							 log_uid = room.log_uid,
							 gametype=room.gametype,
                             user_id=player.oid, 
                             place = room.place_id,                           
							 service_gold=-gold})
    if not STRICT_CHECK then
        db_add_sql_check_value(Return, {true, [[update user_info set gold=gold+($1::int) where user_id=$2::bigint returning gold>=0]], 
                                        {gold, player.oid}}, 
                                        get_call_next(caller, msg, player.oid), 
                                        get_call_next(caller, 7, player.oid))	
    else
        db_add_sql_check_value(Return, {true, [[update user_info set gold=gold+($1::int) where user_id=$2::bigint returning gold=$3::int]], 
                                       {gold, player.oid, player.gold}}, 
                                       get_call_next(caller, msg, player.oid), 
                                       get_call_next(caller, 7, player.oid))
    end
end

function db_minus_gold(caller, Return, player, gold, reason)
    player.gold = player.gold - gold 
	local room = player.room
	assert(gold >= 0)
	assert(player.gold >= 0)
    local msg = encode_json({msg_type='minus_gold', 	
                             reason = reason or 0, 
							 log_uid = room.log_uid,
							 gametype = room.gametype,
                             user_id=player.oid, 
                             place = room.place_id,
							 service_gold=gold})
    if not STRICT_CHECK then
        db_add_sql_check_value(Return, {true, [[update user_info set gold=gold-($1::int) where user_id=$2::bigint returning gold>=0]], 
                                        {gold, player.oid}}, 
                                        get_call_next(caller, msg, player.oid), 
                                        get_call_next(caller, 9, player.oid))	
    else
        db_add_sql_check_value(Return, {true, [[update user_info set gold=gold-($1::int) where user_id=$2::bigint returning gold=$3::int]], 
                                       {gold, player.oid, player.gold}}, 
                                       get_call_next(caller, msg, player.oid), 
                                       get_call_next(caller, 9, player.oid))
    end
end
-------------------------------------------------------------------------------

---------------------------------房卡变化----------------------------------------------
function db_add_room_card(caller, Return, player, card_count, reason)
	player.room_card = player.room_card + card_count
	local room = player.room
	assert(card_count >= 0)
	assert(player.room_card >= 0)
	local msg = encode_json({msg_type='add_card', 	
							 game_log_group_uid = room.log_group_uid,
							 game_log_uid = room.log_uid,
                             gametype = room.gametype,
                             reason = reason or 0,
							 user_id=player.oid, 
                             consume_count=-card_count,
                             room_uuid=room.uuid,
                             pos = room.pos,
                             club_id = room.club_id,
                             use_fund = room.use_fund})
    if not STRICT_CHECK then
        db_add_sql_check_value(Return, {true, [[update user_info set room_card=room_card+($1::int) where user_id=$2::bigint returning room_card>=0]], 
                                        {card_count, player.oid}}, 
                                        get_call_next(caller, msg, player.oid), 
                                        get_call_next(caller, 5, player.oid))	
    else
        db_add_sql_check_value(Return, {true, [[update user_info set room_card=room_card+($1::int) where user_id=$2::bigint returning room_card=$3::int]], 
                                       {card_count, player.oid, player.room_card}}, 
                                       get_call_next(caller, msg, player.oid), 
                                       get_call_next(caller, 5, player.oid))
    end

    handle_task(Return, caller, player.oid, 6, card_count)
end

function db_minus_room_card(caller, Return, player, card_count, reason)
    player.room_card = player.room_card - card_count
	assert(card_count >= 0)
    if player.room_card < 0 then
        print(player.room_card, card_count)
    end
	assert(player.room_card >= 0)
	local room = player.room
	local msg = encode_json({msg_type='minus_card', 	
							 game_log_group_uid = room.log_group_uid,
							 game_log_uid = room.log_uid,
                             gametype = room.gametype,
                             reason = reason or 0,
                             user_id=player.oid, 
                             pos = room.pos,
                             consume_count=card_count,
                             room_uuid=room.uuid})
    if not STRICT_CHECK then
        db_add_sql_check_value(Return, {true, [[update user_info set room_card=room_card-($1::int) where user_id=$2::bigint returning room_card>=0]], 
                                        {card_count, player.oid}}, 
                                        get_call_next(caller, msg, player.oid), 
                                        get_call_next(caller, 3, player.oid))	
    else
        db_add_sql_check_value(Return, {true, [[update user_info set room_card=room_card-($1::int) where user_id=$2::bigint returning room_card=$3::int]], 
                                       {card_count, player.oid, player.room_card}}, 
                                       get_call_next(caller, msg, player.oid), 
                                       get_call_next(caller, 3, player.oid))
    end

    handle_task(Return, caller, player.oid, 6, card_count)
end


function add_player_exp(Return, room)
    for i, v in ipairs(room.seats) do
        if v ~= none then
            db_add_sql(Return, {update_return(1), [[update user_info set exp=exp+$1::int where user_id=$2::bigint]], {1, v.player.oid}})
        end
    end
end

function insert_user_game_group(Return, user_id, room)
    local msg = {group_uid=room.log_group_uid, ju_count=room.game_config.ju_count, time=room.game_log.begin_time, gametype=room.gametype, place=room.place_id}
    --为了和以前兼容，只有俱乐部游戏使用新的表
    if room.pos == 2 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('club_logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(msg)})
    elseif room.pos == 3 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('arena_logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(msg)})
    elseif room.pos == 1 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(msg)})
    end
end

function insert_user_niuniu_game_group(Return, user_id, pos, info)
    --为了和以前兼容，只有俱乐部游戏使用新的表
    if pos == 2 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('club_logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(info)})
    elseif pos == 3 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('arena_logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(info)})
    elseif pos == 1 then
        add_db_log_sql_no_check(Return,
        [[
            select add_user_game_group('logs', $1::bigint, 500, $2::text::jsonb);
        ]], {user_id, encode_json(info)})
    end
end

--type 目前有三种 player proxy fund
--做好兼容，使代理可以创建房间

function get_room_info_table(pos)
    if pos == 1 then
        return 'card_room_info'
    elseif pos == 2 then
        return 'club_card_room_info'
    elseif pos == 3 then
        return 'arena_room_info'
    end
end

-------------------------------------------------------------------------------
function change_room_info_state(Return, room)
    if room.state == 2 then
        db_add_sql(Return, {update_return(1), 
            string.format([[update %s set restore_room_card=0, state=$1::int where pwd=$2]], room.room_info_table_name), {room.state, room.passwd}})
    else
        db_add_sql(Return, {update_return(1), 
            string.format([[update %s set state=$1::int where pwd=$2]], room.room_info_table_name), {room.state, room.passwd}})
    end

    if room.pos == 2 and room.state == 1 then
        add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id,
            msg=encode_json({type='club_change_room_state', room_id=room.passwd, club_id=room.club_id, state=room.state or 0})})
    elseif room.pos == 1 and room.game_config.mode ~= nil and room.game_config.mode >= 100 and room.game_config.mode <200 then
        add_send_lobby_notify(Return, {msg_type='send_to_room_entered_players', user_id=room.creater_id,room_uuid=room.uuid,
            msg=encode_json({type='hall_change_room_state', room_id=room.passwd, club_id=room.club_id, state=room.state or 0, uuid=room.uuid})})
    elseif room.pos == 3 then 
        --add_send_lobby_notify(Return, {msg_type='send_to_all_players', user_id=room.creater_id,
        --    msg=encode_json({type='arena_change_room_state', room_id=room.passwd, gametype = room.gametype, state=room.state or 0})})
    end
end

function change_room_player_count(Return, room)
    db_add_sql(Return, {update_return(1), 
        string.format([[update %s set player_count=$1 where pwd=$2]], room.room_info_table_name), {room.player_count, room.passwd}})
    if room.pos == 2 then  
        if room.game_config.mode and room.game_config.mode >= 100 and room.game_config.mode <200 then     
            add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id,
                msg=encode_json({type='club_change_room_count', room_id=room.passwd, club_id=room.club_id, count=room.player_count or 0})})
        else
            local portraits = {}
            for i, v in ipairs(room.seats) do
                if v ~= none and v.player then
                    table.insert(portraits, {user_id=v.player.oid, sex=v.player.sex, nick_name=v.player.nick_name, portrait=v.player.portrait})
                end
            end
            add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id,
                msg=encode_json({type='club_change_room_count', room_id=room.passwd, club_id=room.club_id, portraits=portraits, count=room.player_count or 0})})
        end
    elseif room.pos == 1 and room.game_config.mode ~= nil and room.game_config.mode >= 100 and room.game_config.mode <200 then --niuniu 
        add_send_lobby_notify(Return, {msg_type='send_to_room_entered_players', user_id=room.creater_id,room_uuid=room.uuid,
                msg=encode_json({type='hall_change_room_count', room_id=room.passwd, count = room.game_config.player_count, cur_count=room.player_count or 0, uuid=room.uuid})}) 
    elseif room.pos == 3 then 
        --add_send_lobby_notify(Return, {msg_type='send_to_all_players',
        --        msg=encode_json({type='arena_change_room_count', room_id=room.passwd, gametype = room.gametype, count=room.player_count or 0})})
    end
end

function change_room_ju_count(Return, room)
    db_add_sql(Return, {update_return(1), 
        string.format([[update %s set cur_ju_count=$1 where pwd=$2]], room.room_info_table_name), {room.ju_count, room.passwd}})

    if room.pos == 1 and room.game_config.mode ~= nil and room.game_config.mode >= 100 and room.game_config.mode <200 then --niuniu 
        add_send_lobby_notify(Return, {msg_type='send_to_room_entered_players', user_id=room.creater_id,room_uuid=room.uuid,
            msg=encode_json({type='hall_change_room_round', room_id=room.passwd, round = room.game_config.ju_count, cur_round=room.ju_count or 0, uuid=room.uuid})}) 
    end

    if room.pos == 2 and (room.game_config.mode == nil or room.game_config.mode < 100 or room.game_config.mode >= 200) then    
        add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id,
            msg=encode_json({type='club_change_room_ju_count', room_id=room.passwd, club_id=room.club_id, count=room.ju_count or 0})})
    end
end

function making_sure_card_consume(Return, room)
    if room.restore_room_card > 0 then
        local card_consume = room.restore_room_card
         add_card_consume_log(Return, {
                 game_log_group_uid = room.log_group_uid,
			     game_log_uid = room.log_uid,
		         gametype = room.gametype,
		         user_id=room.creater_id, 
                 consume_count=room.restore_room_card,
                 room_uuid = room.uuid,
                 club_id=room.club_id,
                 use_fund=room.use_fund,
                 pos = room.pos,
                 reason = 0
         }, room)

         

        room.restore_room_card = 0
        room.state = 2
        --如果change state 2成功， card就真正被消耗了
        change_room_info_state(Return, room)
    end

    return 0
end

--room dismiss will call this
function restore_card_when_room_dismiss(roomid, tstate)
    local room = global_bloodwar_rooms[roomid]

    if room == nil then
        return
    end

    local Return = {}
    local trans = {} 

    room.restore_room_card = room.restore_room_card or 0

    if room.restore_room_card > 0 then
        --使用基金
        if room.use_fund > 0 then
            --加回基金
            table.insert(trans, {"sql_no_check",
                update_return(1), 
                [[update club_info set room_card=room_card+$1 where club_id=$2]], 
                {room.restore_room_card, room.club_id}})

            add_db_log_sql_no_check(Return, 
                [[insert into club_fund_log(club_id, user_id, room_card, use_type) values($1, $2, $3, 2)]], {room.club_id, room.creater_id, room.restore_room_card})
            add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id, 
                msg=encode_json({type='club_change_fund_dismiss', room_card = room.restore_room_card, club_id=room.club_id, nick_name = room.c_name, use_type = 2, user_id = room.creater_id})})
        else
            table.insert(trans, {"sql", 
                update_return(1), 
                [[update user_info set room_card=room_card+$1 where user_id=$2]], 
                {room.restore_room_card, room.creater_id}})
        end

        table.insert(trans, {"sql", 
            delete_return(1), 
            string.format([[delete from %s where restore_room_card=$1 and pwd=$2 and u_id=$3 and uuid=$4]], room.room_info_table_name), 
            {room.restore_room_card, room.passwd, room.creater_id, room.uuid}})
    else 
        table.insert(trans, {"sql", 
            delete_return(1), 
            string.format([[delete from %s where pwd=$1 and u_id=$2 and uuid=$3]], room.room_info_table_name),
            {room.passwd, room.creater_id, room.uuid}})
    end


    db_add_transaction(Return, trans)
    
    if tstate == 'crash' then
        room.state = room.state * 100
    end

    --注意是位置，与游戏逻辑无关
    add_room_info_log(Return, room)  

    if room.pos == 2 then
        add_send_lobby_notify(Return, {msg_type='send_to_club_players', club_id=room.club_id, 
                msg=encode_json({type='club_dismiss_room', room_id=room.passwd, club_id=room.club_id, room_uuid=room.uuid})})
    elseif room.pos == 1 and room.game_config.mode ~= nil and room.game_config.mode >= 100 and room.game_config.mode <200 then
        add_send_lobby_notify(Return, {msg_type='send_to_room_entered_players', room_uuid=room.uuid,
                msg=encode_json({type='hall_dismiss_room', room_id=room.passwd, uuid=room.uuid})})
        db_add_sql_no_check(Return, {[[update user_info_log set entered_room_info=entered_room_info-$1 where entered_room_info ? $1]], {room.uuid}})
    elseif room.pos == 3 then
        --add_send_lobby_notify(Return, {msg_type='send_to_all_players', user_id=room.creater_id,
        --        msg=encode_json({type='arena_dismiss_room', room_id=room.passwd, gametype = room.gametype})})
    end
    
    return Return
end

function add_send_lobby_notify(Return, Args)
    table.insert(Return, {'send_lobby_notify', Args})
end

--分配custom_room, 代理号和玩家号区别
--custom节点, 处于已被玩家占用的节点
--room.pos     1普通房卡入口， 2俱乐部入口， 3竞技场入口
--
function assign_custom_room(payload)
    local custom_config = decode_json(payload.config)
    if public_bloodwar_room_tree[payload.place] then
        for k, v in pairs(public_bloodwar_room_tree[payload.place]['free']) do
            force_change_public_room_tree('assigned', v.roomid)
            v.state = 0
            v.creater_id = payload.oid   --设置创建者id
            v.creater_type = payload.oidtype
            v.c_name = payload.c_name
            v.pos         = payload.pos or 1  --创建房间的位置， 非常重要
            v.club_id      = payload.clubid or 0  
            v.club_name    = payload.club_name or ''
            v.use_fund     = payload.use_fund or 0
            v.uuid         = payload.uuid
            v.passwd = payload.pwd
            local game_config = get_game_config(custom_config)
            v.custom_config = payload.config 
            v.game_config = game_config
            v.game_config.pos = v.pos
            v.game_config.club_id = v.club_id
            v.game_config.club_name = v.club_name or ''
            v.restore_room_card = payload.restore_room_card
            v.create_time = os.time()
       

            v.room_info_table_name = get_room_info_table(v.pos)
            return v.roomid, v.pid
        end
    end

	return -1
end

function get_public_room_pid(place)
   for i=0, 3 do
      for k, v in pairs(public_bloodwar_room_tree[place][3-i]) do
         return v.roomid, v.pid
      end
   end
end


function get_room_info(roomid)
    print(tostring(roomid))
    local room = global_bloodwar_rooms[roomid]

    return {
           ju_count     = room.ju_count or 0,
           status       = room.status or 0,
           creater_id   = room.creater_id or '',
           creater_type = room.creater_type or '',
           club_id      = room.club_id or 0,
           passwd       = room.passwd or '',
           uuid         = room.uuid or ''
        }

end

function get_player_room_info(oid)
    local player = global_players[oid]

    local room = player.room

    if room == nil then
        return {}
    end

    return get_room_info(room.roomid)
end

function dismiss_room(roomid, why)
    local Return = {}
    local room = global_bloodwar_rooms[roomid]

    if room then
        add_dismiss_room(Return, room, 0, why)
    end

    return Return
end

function pack_sc_leave_room_plus(oid, why)
    local player = global_players[oid]

    if player and player.dismiss_why then
        why = player.dismiss_why
    end

    return pack_protocol_to_bin("sc_leave_room",
        {
            result = 0,
            reason = protocol.error_id_and_desc[why],
            why = why
        }
    )
end

function pack_sc_leave_room_plus_nn(oid, why)
    local player = global_players[oid]
    local room = player.room

    if player and player.dismiss_why then
        why = player.dismiss_why
    end

    local dismiss_by_timeout = false
    local stay_room = false

    if room then
        dismiss_by_timeout = (room.ju_count == 0 and (not room.dismiss_apply))
        stay_room = why == 'error_room_dismiss' and room and ((room.ju_count > 1) or (room.ju_count == 1 and room.status==room_not_gaming))
    end

    return pack_protocol_to_bin("sc_leave_room",
        {
            result = 0,
            reason = protocol.error_id_and_desc[why],
            why = why,
            dismiss_by_timeout = dismiss_by_timeout,
            stay_room = stay_room
        }
    )
end

function split(s, delim)
    if type(delim) ~= "string" or string.len(delim) <= 0 then
        return
    end

    local start = 1
    local t = {}
    while true do
        local pos = string.find (s, delim, start, true) -- plain find
        if not pos then
            break
        end

        table.insert (t, string.sub (s, start, pos - 1))
        start = pos + string.len (delim)
    end
    table.insert (t, string.sub (s, start))

    return t
end
