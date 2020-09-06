--[[
local json = require("./lua/game/json")
local room = {
    ENTER_ROOM = 1001, -- 可以继续进入
    FULL_ROOM = 1002, -- 满员1001和1002消息只能回发一个 @see line 20 & 22
    OUT_ROOM = 1003, -- 玩家离开房间
    KICK_OUT = 1004, -- 被踢出房间
    SEAT_DOWN = 1005, -- 坐下
}

local action = {
    PASS = 2001
}
local playerSize = 0
local switch = {
    [room.ENTER_ROOM] = function(m)
        playerSize = playerSize + 1
        local player = m.what-- json.decode(m.what)
        print("player.uuid = ", player.uuid)
        --players[player.uuid] = player
        -- 3个人一个房间，发送房间已满
        if (playerSize == 3) then
            local full = { id = room.FULL_ROOM }
            --out:send(json.encode(full))
            --out:send(full)
            print("房间满了")
        else

            table.insert(m.to, player.uuid)
            print(json.encode(m))
            --out:send(json.encode(m))
            --out:send({ id = room.ENTER_ROOM })

            print("可以进入")
        end
        -- 发送坐下了
        local seatDown = { id = room.SEAT_DOWN, to = { [1] = player.uuid } }
        --local ss = json.encode(seatDown)
        out:send(seatDown)
    end,
    [action.PASS] = function(m)
        print("pass id =  ", m.id)
        print("热更新，想改就改哦，巴适1")
        local t = {}
        print(string.byte("a"))
        table.insert(t, string.byte("a"))
        print(t)
        --out:send(json.encode(m))
        --谁发了，发给谁
        m.to = {[1]=m.from}
        --out:send(m)
]]

--[[        out:send(m)
        out:send(m)
        out:send(m)
        out:send(m)
        out:send(m)]]--[[

    end,
    [room.OUT_ROOM] = function(m)
        print("用户" .. m.from .. "离开房间")
    end,
    [666] = function(m)
        print("do hot update")
        if m.what ~= nil then
            local ok = hot_update_code(m.what)
            if ok then
                print("热更新成功")
            else
                print("热更新出错啦")
            end
        end
    end,
}

function onmessage(m)
    print(m)
    -- 测试出错
    --print(x.x)
    hotupdate()
    m = json.decode(m)
    if m ~= nil then
        print(m, type(m), m.from, m.id, "xx")
        local f = switch[m.id]
        if (f) then
            f(m)
        else
            print("unexpected message id ", m.id, m)
        end
    end
end

function hotupdate()
    print("ok hot 999  ...")
end]]
local protobuf = require './lua/testing/protobuf'
local roomId
function init(id)
    roomId = id
    print("init room ", id)
end
function onmessage(m)
    hotupdate()
    print("on::",m)
end

function hotupdate()
    --print(hello)
    print("ok hot 666  ...")
end
