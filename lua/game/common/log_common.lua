---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--普通和俱乐部房卡消耗和赢取总记录
--consume_log 房卡消耗日志根据位置判断写入那些表, 房卡的消耗走流水记录后，再提取写其他日志表
--流水日志处理房卡消耗，其他user_status关注游戏局数
function add_card_consume_log(Return, info, room)
    add_db_log_sql(Return,
      [[insert into card_consume_log(user_id, gametype, consume_count, game_log_group_uid, game_log_uid, club_id, use_fund, room_uuid, reason, pos) 
            values($1::bigint, $2::varchar(32), $3::int, $4::varchar(128), $5::varchar(128), $6::bigint, $7::int, $8::varchar(128), $9::int, $10::int)]],
          {info.user_id, info.gametype, info.consume_count, info.game_log_group_uid, info.game_log_uid, room.club_id, room.use_fund, info.room_uuid, info.reason, room.pos})

    add_card_user_status_log(Return, {
        user_id = info.user_id,  
        gametype= info.gametype,
        consume_count=info.consume_count,
    })

    add_card_server_status_day_log(Return, {
        gametype = info.gametype,
        consume_count = info.consume_count    
    })
end

function add_card_server_status_day_log(Return, info)
    add_db_log_sql(Return,
    [[insert into card_server_status_day_log(gametype, consume_count, game_count, game_group4_count, game_group8_count) values($1::varchar(20), $2::int, $3::int, $4::int, $5::int)
    on conflict(gametype, date_day)
    do update set consume_count     = card_server_status_day_log.consume_count+$2::int,
                  game_count        = card_server_status_day_log.game_count+$3::int,
                  game_group4_count = card_server_status_day_log.game_group4_count+$4::int,
                  game_group8_count = card_server_status_day_log.game_group8_count+$5::int,
				  last_update_date  = now()
    ]],
        {info.gametype, info.consume_count or 0, info.game_count or 0, info.game_group4_count or 0, info.game_group8_count or 0})
end

function add_card_user_status_log(Return, info)
    add_db_log_sql(Return,
    [[insert into card_user_status_log(user_id, gametype, consume_count, game_count, game_group4_count,
game_group4_win_count, game_group8_count, game_group8_win_count) values($1::bigint, $2::varchar(20), $3::int, $4::int, $5::int, $6::int, $7::int, $8::int)
    on conflict(user_id, gametype)
    do update set consume_count     	= card_user_status_log.consume_count+$3::int,
                  game_count        	= card_user_status_log.game_count+$4::int,
                  game_group4_count 	= card_user_status_log.game_group4_count+$5::int,
                  game_group4_win_count = card_user_status_log.game_group4_win_count+$6::int,
                  game_group8_count  	= card_user_status_log.game_group8_count+$7::int,
                  game_group8_win_count = card_user_status_log.game_group8_win_count+$8::int,
				  last_update_date      = now()
    ]],
        {info.user_id, info.gametype, info.consume_count or 0, info.game_count or 0, info.game_group4_count or 0, info.game_group4_win_count or 0, info.game_group8_count or 0, info.game_group8_win_count or 0})

	add_card_user_status_day_log(Return, info)
end

function add_card_user_status_day_log(Return, info)
    add_db_log_sql(Return,
    [[insert into card_user_status_day_log(user_id, gametype, consume_count, game_count, game_group4_count,
game_group4_win_count, game_group8_count, game_group8_win_count) values($1::bigint, $2::varchar(20), $3::int, $4::int, $5::int, $6::int, $7::int, $8::int)
    on conflict(user_id, gametype, date_day)
    do update set consume_count     	= card_user_status_day_log.consume_count+$3::int,
                  game_count        	= card_user_status_day_log.game_count+$4::int,
                  game_group4_count 	= card_user_status_day_log.game_group4_count+$5::int,
                  game_group4_win_count = card_user_status_day_log.game_group4_win_count+$6::int,
                  game_group8_count 	= card_user_status_day_log.game_group8_count+$7::int,
                  game_group8_win_count = card_user_status_day_log.game_group8_win_count+$8::int,
				  last_update_date  	= now()
    ]],
        {info.user_id, info.gametype, info.consume_count or 0, info.game_count or 0, info.game_group4_count or 0, info.game_group4_win_count or 0, info.game_group8_count or 0, info.game_group8_win_count or 0})
end

-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------
---gamelog, 添加游戏日志，根据位置判断，协议那张表
function add_game_log(Return, room)
    --if room.pos == 1 then
        add_card_game_log(Return, room)
    --elseif room.pos == 2 then
    --    add_club_game_log(Return, room)
    --elseif room.pos == 3 then
    --    add_arena_game_log(Return, room)
    --end
end

function add_card_game_log(Return, room)
    local player_oids = {}
    for i, v in ipairs(room.seats) do
        table.insert(player_oids, v.player.oid)
    end
print("--------------------------- add_game_log,", room.gametype)
    add_db_log_sql(Return, {room.log_uid, room.log_uid, 'classic_ddz', 'classic_ddz', encode_json(room.game_log), room.game_log.begin_time, room.uuid}, player_oids)
end

function add_club_game_log(Return, room)
    add_db_log_sql(Return, 
    [[insert into club_card_game_log(log_group_uid, log_uid, gametype, room_pwd, game_log, begin_date, club_id, use_fund, room_uuid) 
    values($1::varchar(128), $2::varchar(128), $3::varchar(32), $4::varchar(20), $5::text::jsonb, to_timestamp($6::int), $7::int, $8::int, $9::varchar(128))]],
    {room.log_group_uid, room.log_uid, room.gametype, room.passwd, encode_json(room.game_log), room.game_log.begin_time, room.club_id, room.use_fund, room.uuid})
end

function add_arena_game_log(Return, room)
    add_db_log_sql(Return, 
        [[insert into arena_game_log(log_group_uid, log_uid, gametype, room_pwd, game_log, begin_date, room_uuid) 
        values($1::varchar(128), $2::varchar(128), $3::varchar(32), $4::varchar(20), $5::text::jsonb, to_timestamp($6::int), $7::varchar(128))]],
        {room.log_group_uid, room.log_uid, room.gametype, room.passwd, encode_json(room.game_log), room.game_log.begin_time, room.uuid})
end

-----------------------------------------------------------------
-----------------------------------------------------------------
----------------------------------------------------------------
--room log 房间创建日志，根据位置判断，写入那些表
function add_room_info_log(Return, room)
    if room.pos == 1 or room.pos == 2 then
        add_card_room_info_log(Return, room)
    elseif room.pos == 3 then
        add_arena_room_info_log(Return, room)
    end
end

function add_card_room_info_log(Return, room)
    add_db_log_sql(Return,
        [[insert into card_room_info_log(u_id, u_idtype, club_id, use_fund, room_gametype, place, pwd, config, state, create_date, over_date, uuid, pos, player_count, cur_ju_count, max_ju_count)
            values($1::bigint, $2::varchar(32), $3::int, $4::int, $5::varchar(32), $6::varchar(32), $7::varchar(32), $8::text::jsonb, $9::int, to_timestamp($10::int), 
            to_timestamp($11::int), $12::varchar(128), $13::int, $14::int, $15::int, $16::int)]],
        {room.creater_id, room.creater_type, room.club_id, room.use_fund, room.gametype, room.place_id,
            room.passwd, room.custom_config, room.state, room.create_time, os.time(), room.uuid, room.pos,
            room.player_count or 0, room.ju_count or 0, room.game_config.ju_count or 0})
end

function add_arena_room_info_log(Return, room)
    add_db_log_sql(Return,
        [[insert into arena_room_info_log(u_id, u_idtype, club_id, use_fund, room_gametype, place, pwd, config, state, create_date, over_date, uuid, pos, player_count, cur_ju_count, max_ju_count)
            values($1::bigint, $2::varchar(32), $3::int, $4::int, $5::varchar(32), $6::varchar(32), $7::varchar(32), $8::text::jsonb, $9::int, to_timestamp($10::int), 
            to_timestamp($11::int), $12::varchar(128), $13::int, $14::int, $15::int, $16::int)]],
        {room.creater_id, room.creater_type, room.club_id, room.use_fund, room.gametype, room.place_id,
            room.passwd, room.custom_config, room.state, room.create_time, os.time(), room.uuid, room.pos,
            room.player_count or 0, room.ju_count or 0, room.game_config.ju_count or 0})
end

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--金币游戏相关日志记录, 主要是服务费
function add_gold_consume_log(Return, info, player) 
    local room = player.room
    if info.reason == 0 then  --服务费
        add_db_log_sql(Return,
            [[insert into arena_user_service_gold_log(user_id, service_gold, place) 
                values($1::bigint, $2::numeric(15, 2), $3::varchar(32))]],
            {info.user_id, info.service_gold or 0, info.place}
            )

        add_gold_server_status_day_log(Return, info, room)
        add_gold_user_status_log(Return, player, info)
    end
end

--服务器总服务费收集
function add_gold_server_status_day_log(Return, info, room)
    local gametype = room.gametype
    local place = room.place_id

    if room.pos == 1 then

    elseif room.pos == 2 then 

    elseif room.pos == 3 then
        add_db_log_sql(Return,
          [[insert into arena_server_status_day_log(gametype, place, service_gold, game_count) 
              values($1::varchar(20), $2::varchar(32), $3::numeric(15, 2), $4::numeric(15, 2))
              on conflict(place, date_day)
              do update set game_count=arena_server_status_day_log.game_count+$4::numeric(15, 2), 
                            service_gold=arena_server_status_day_log.service_gold+$3::numeric(15,2), 
                            last_update_date=now()]],
            {gametype, place, info.service_gold or 0, info.game_count or 0})
    end
end

--每一局结束统计
function add_gold_user_status_log(Return, player, info)
    local room = player.room
    local place = player.room.place_id
    local gametype = player.room.gametype
    local user_id = player.oid
 

    --根据位置来选择插入的表
    add_db_log_sql(Return, [[insert into arena_user_status_log(user_id, gametype, place, win_gold, lose_gold, service_gold, game_count)
                           values($1::bigint, $2::varchar(64), $3::varchar(20), $4::numeric(12,2), $5::numeric(12,2), $6::numeric(12,2), $7::numeric(12,2))
                           on conflict(user_id, place) do update set                              
                              win_gold = arena_user_status_log.win_gold+($4::numeric(12,2)),
                              lose_gold = arena_user_status_log.lose_gold+($5::numeric(12,2)),
                              service_gold = arena_user_status_log.service_gold+($6::numeric(12,2)),
                              game_count = arena_user_status_log.game_count+($7::numeric(12,2)),
                              last_update_date=now()]],
                              {user_id, gametype, place, info.win_gold or 0, info.lose_gold or 0, info.service_gold or 0, info.game_count or 0})
    add_gold_user_status_day_log(Return, player, info)
end

function add_gold_user_status_day_log(Return, player, info)
    local room = player.room
    local place = player.room.place_id
    local gametype = player.room.gametype
    local user_id = player.oid
   
   

    --根据位置来选择插入的表
    add_db_log_sql(Return, [[insert into arena_user_status_day_log(user_id, gametype, place, win_gold, lose_gold, service_gold, game_count)
                           values($1::bigint, $2::varchar(64), $3::varchar(20), $4::numeric(12,2), $5::numeric(12,2), $6::numeric(12,2), $7::numeric(12,2))
                           on conflict(user_id, place, date_day) do update set                             
                              win_gold = arena_user_status_day_log.win_gold+($4::numeric(12,2)),
                              lose_gold = arena_user_status_day_log.lose_gold+($5::numeric(12,2)),
                              service_gold = arena_user_status_day_log.service_gold+($6::numeric(12,2)),
                              game_count = arena_user_status_day_log.game_count+($7::numeric(12,2)),
                              last_update_date=now()
                              ]],
                              {user_id, gametype, place, info.win_gold or 0, info.lose_gold or 0, info.service_gold or 0, info.game_count or 0})
end
