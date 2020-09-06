DEBUG = false
STRICT_CHECK = false

luapath = '/root/golang/src/server/lua/game'
--luapath = 'D:/gohub/src/server/lua/game'

package.path = [[./?.lua;./?/init.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua]]
package.cpath = [[./?.so;/usr/local/lib/lua/5.1/?.so]]

--local pre = string.sub(luapath, 1, -6)
--set_luapath(pre)
local common_path = luapath .. '/common/?.lua'
local proto_path = luapath .. '/classic_ddz/protocol/?.lua'
local game_path = luapath .. '/classic_ddz/?.lua'
package.path = package.path .. ';' .. game_path .. ';' .. common_path .. ';' .. proto_path
--package.cpath= package.cpath .. ';' .. (pre..'?.so')


local print = _G.print
_G.print = function(...)
    local var = ""
    for k, v in ipairs({ ... }) do
        var = var .. tostring(v)
    end

    var = string.gsub(var, '\n', '\r')
    var = var .. '\r'

    print(var)
end

--设置工作路径
function set_lua_path()

end

function get_lua_path(path)

end

function get_game_path()
    return luapath .. '/test_game'
end

function get_game_common_path()
    return luapath .. '../common/game_common.lua'
end

function get_log_common_path()
    return luapath .. '../common/log_common.lua'
end

function get_utility_common_path()
    return luapath .. '../common/utility_common.lua'
end

function get_opcode_common_path()
    return luapath .. '../common/opcode_common.lua'
end

function set_luapath(path)
    luapath = path
    game_luapath = path
end

function get_env(key)
    return appenv[key]
end

function _G.print_r (t, name, indent)
    if not DEBUG then
        return
    end
    local tableList = {}
    function table_r (t, name, indent, full)
        local serial = string.len(full) == 0 and name
                or type(name) ~= "number" and '["' .. tostring(name) .. '"]' or '[' .. name .. ']'
        io.write(indent, serial, ' = ')
        if type(t) == "table" then
            if tableList[t] ~= nil then
                io.write('{}; -- ', tableList[t], ' (self reference)\n\r')
            else
                tableList[t] = full .. serial
                if next(t) then
                    -- Table not empty
                    io.write('{\n\r')
                    for key, value in pairs(t) do
                        table_r(value, key, indent .. '\t', full .. serial)
                    end
                    io.write(indent, '};\n\r')
                else
                    io.write('{};\n\r')
                end
            end
        else
            io.write(type(t) ~= "number" and type(t) ~= "boolean" and '"' .. tostring(t) .. '"'
                    or tostring(t), ';\n\r')
        end
    end
    table_r(t, name or '__unnamed__', indent or '', '')
end

function decode_first_packet(place, bin)
    _G.print(#bin)
    local crypt = require('crypt')
    local cjson_safe = require('cjson.safe')

    local test, packet_bin, err = pcall(function()
        return crypt.desdecode("FcYpB3xi", bin)
    end)
    if test then
        _G.print(packet_bin)
        local obj = cjson_safe.decode(packet_bin)
        print_r(obj)
        if obj.msg_type == 'enter_room' then
            return 'enter_room', obj.token, obj.room_id, obj.room_pwd
        elseif obj.msg_type == 'create_room' then
            return 'enter_room', obj.token, 0, obj.room_pwd
        end
    end
    _G.print(packet_bin)

    return false, err
end
