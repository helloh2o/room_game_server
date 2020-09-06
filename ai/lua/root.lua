--
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 2020/7/30
-- Time: 16:01
-- To change this template use File | Settings | File Templates.
--

luapath = '/root/golang/src/server/ai/lua'

--package.path = [[./?.lua;./?/init.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua]]
package.path = [[./?.lua;./?/init.lua;/root/golang/src/server/ai/lua/?.lua]]
package.cpath = [[./?.so;/usr/local/lib/lua/5.1/?.so]]


function get_game_path()
    return luapath
end

