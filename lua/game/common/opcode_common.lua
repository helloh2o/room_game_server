-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--------------------------------dbop-----------------------------------------------------------
function add_record_log(Return, tablename, content)
    table.insert(Return, {'record_log', {tablename, encode_json(content)}})
end

function db_add_sql_check_value(Return, sql, thenreturn, elsereturn)
    thenreturn = thenreturn or {}
    elsereturn = elsereturn or {}
    table.insert(Return, {'sql_check_value', {sql, thenreturn, elsereturn}})
end

function db_add_sql(Return, sql, thenreturn, elsereturn)
    thenreturn = thenreturn or {}
    elsereturn = elsereturn or {}
    table.insert(Return, {'sql', {sql, thenreturn, elsereturn}})
end

function db_add_sql_no_check(Return, sql)
    thenreturn = thenreturn or {}
    elsereturn = elsereturn or {}
    table.insert(Return, {'sql_no_check', sql})
end


function db_add_sql_with_pool(Return, sql, thenreturn, elsereturn)
    thenreturn = thenreturn or {}
    elsereturn = elsereturn or {}
    table.insert(Return, {'sql_with_pool', {sql, thenreturn, elsereturn}})
end

function db_add_transaction(Return, sqls, thenreturn, elsereturn)
    thenreturn = thenreturn or {}
    elsereturn = elsereturn or {}
    table.insert(Return, {'sql_transaction', {sqls, thenreturn, elsereturn}})
end

function db_add_transaction_with_pool(Return, pool, sqls, thenreturn, elsereturn)
    thenreturn = thenreturn or {}
	  elsereturn = elsereturn or {}
	  table.insert(Return, {'sql_transaction_with_pool', {pool, sqls, thenreturn, elsereturn}})
end
function add_erlang_apply(Return, mod, fun, args)
    table.insert(Return, {'erlang_apply', {mod, fun, args}})
end
function add_spawn_erlang_apply(Return, mod, fun, args)
    table.insert(Return, {'spawn_erlang_apply', {mod, fun, args}})
end
function add_db_log_sql(Return, params, player_oids)
    table.insert(Return, {'log_sql', params, player_oids})
end

function add_db_log_sql_no_check(Return, sql, params)
    table.insert(Return, {'log_sql_no_check', {sql, params}})
end

function add_db_game_log_sql(Return, sql, params)
    table.insert(Return, {'game_log_sql', {sql, params}})
end

function add_dismiss_room(Return, room, time, why)
    room.dismiss = true

    for _, v in ipairs(room.seats) do
        if v ~= 'none' then
            v.player.dismiss_why = why
        end
    end
    if time == nil or time == 0 then
        table.insert(Return, {'dismiss', 0})
    else
        add_auto_dismiss_timer(Return, time)
    end
end

function server_error_log(Return, log)
    add_db_log_sql(Return, [[insert into server_error_log(error) values($1::text::jsonb)]], {encode_json(log)})
end

function erlang_throw(Return, err)
    add_erlang_apply(Return, erlang.atom('erlang'), erlang.atom('throw'), {err})
end

------------------------------------------------------------opcode------------------------------------

function add_send(Return, pid, packet_bin, seat, room)
    assert(pid ~= "none") 
    assert(pid ~= nil)
    if (seat ~= nil) then
       assert(packet_bin.id ~= 0)
       seat.action_seq = getUUID()
       seat.action_bin = protobuf.encode(
          "gameserver.protocol", 
          {id = packet_bin.id, content=packet_bin.content})
    end
 
    add_send_packet_to_op_seq(Return, pid, packet_bin)
 end
 
 function add_cast_msg(Return, pid, msg)
    table.insert(Return, {'cast_msg', {pid, msg}})
 end
 
 function add_info_msg(Return, pid, msg)
    table.insert(Return, {'info_msg', {pid, msg}})
 end
 
 function add_send_msg(Return, pid, msg)
    table.insert(Return, {'send_msg', {pid, msg}})
 end
 
 function add_broadcast_all_msg(Return, msg)
     table.insert(Return, {'broadcast_all_msg', msg})
 end
 
 function add_close_player(Return, pid, message)
     table.insert(Return, {'close_player', {pid, message}})
 end
 
 function add_debug_log(Return, log)
     table.insert(Return, {'debug_log', log})
 end
 
 function add_info_log(Return, log)
     table.insert(Return, {'info_log', log})
 end
 
 function add_error_log(Return, log)
     table.insert(Return, {'error_log', log})
 end
 
 function add_send_packet_to_op_seq(Return, pid, packet)
     for i, v in ipairs(Return) do
         local op = v[1]
         local args = v[2]
 
         if (op == 'send' and args[1] == pid) then
             table.insert(args[2], packet)
             return
         end
     end
 
     table.insert(Return, {'send', {pid, {packet}} })
 end
 
 function add_bot(Return, gametype)
     table.insert(Return, {'add_bot', gametype})
 end
 
 function add_send_bin(Return, pid, packet)
     assert(pid ~= "none")
     assert(pid ~= nil)
     table.insert(Return, {'send', {pid, packet}})
 end
 
 --这是
 function add_enter_room(Return, pids, room_id)
     table.insert(Return, {'enter_room', {pids, room_id}})
 end
 
 function add_enter_match_room(Return, pids, room_id)
     table.insert(Return, {'enter_match_room', {pids, room_id}})
 end
 
 function add_send_to_room_not_auto(Return, packet)
     table.insert(Return, {'send_to_room_not_auto', packet})
 end
 
 function add_send_to_room_only(Return, packet)
     table.insert(Return, {'send_to_room_only', packet})
 end
 
 function add_send_to_room(Return, packet)
     table.insert(Return, {'send_to_room', packet})
 end
 
 function add_force_hu(Return, oid)
    table.insert(Return, {'force_hu', oid})
 end
 
 function transform_send_to_send_to_room_not_auto(Return)
    for i, v in ipairs(Return) do
       if v[1] == 'send' or v[1] == 'delay_send' then
          v[1] = 'send_to_room_not_auto'
       end
    end
 end
 
 function transform_send_to_send_to_room_only(Return)
    for i, v in ipairs(Return) do
       if v[1] == 'send' or v[1] == 'delay_send' then
          v[1] = 'send_to_room_only'
       end
    end
 end
 
 function transform_send_to_send_to_room(Return)
    for i, v in ipairs(Return) do
       if v[1] == 'send' or v[1] == 'delay_send' then
          v[1] = 'send_to_room'
       end
    end
 end

function add_timer(Return, pid, timer)
    if timer[2] > 0 then
        table.insert(Return, {'start_timer', {pid, timer}})
    end
end

function add_waiting_game_timer(Return, time, room)
    time = time or 600 
    add_timer(Return,
              'none',
              {'waiting_game_timer', time*1000, room.ju_count or 0}
    )
end

function restore_game_timer(Return, room)
    for i, v in ipairs(room.seats) do
        if v ~= 'none' then
            local player = v.player
            add_cast_msg(Return, player.pid, 'restore_game_timer')
        end
    end
end
