local uuid = require('uuid4')
local socket = require('socket')
local cjson_safe    = require('cjson.safe') 

function encode_json(v)
    return cjson_safe.encode(v)
end

function decode_json(v)
   return cjson_safe.decode(v)
end

function round(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
end

function sort_table(t)
	table.sort(t, function (a, b) return a < b end)
end

function getUUID()
    return uuid.getUUID() ..'-'.. socket.gettime()
end
----------------------------------------------------------------------------------------------------------
----------------------------asyncop-----------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
function check_global_next()
    for k, v in pairs(global_next) do
        local pid = erlang.call('util', 'binary_to_pid', {k}).result
        local alive = erlang.call('erlang', 'is_process_alive', {pid}).result

        if not alive then
            global_next[k] = nil
        end
    end
end

function call_next(caller, flag, info)
    return global_next[caller](flag, info)
end

function get_call_next(caller, flag, info)
    return {{'call_next', {caller, flag or '', info or ''}}}
end

function get_erlang_result_call_next(caller, flag, mod, fun, args)
    return {{'erlang_result_call_next', {caller, flag or '', mod, fun, args}}}
end

function add_get_erlang_result_call_next(Return ,caller, flag, mod, fun, args)
    return table.insert(Return, {'erlang_result_call_next', {caller, flag or '', mod, fun, args}})
end

function clear_call_next(caller)
    global_next[caller] = nil
end

function PrintTable( tbl , level, filteDefault)
    if tbl then
        local msg = ""
        filteDefault = filteDefault or true
        level = level or 1
        local indent_str = ""
        for i = 1, level do
            indent_str = indent_str.."  "
        end

        print(indent_str .. "{")
        for k,v in pairs(tbl) do
            if filteDefault then
                if k ~= "_class_type" and k ~= "DeleteMe" then
                    local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
                    print(item_str)
                    if type(v) == "table" then
                        PrintTable(v, level + 1)
                    end
                end
            else
                local item_str = string.format("%s%s = %s", indent_str .. " ",tostring(k), tostring(v))
                print(item_str)
                if type(v) == "table" then
                    PrintTable(v, level + 1)
                end
            end
        end
        print(indent_str .. "}")
    else
        print("invalid table")
    end
end
