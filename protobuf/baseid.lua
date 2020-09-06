---
--- Created by Ayoo.
--- DateTime: 2020/4/27 11:18
---

local baseid = {
    ---------------------------- LEAF Protocol------------------------
    Protocol = 0, -- 游戏通用消息
    CsLogin = 1, -- 登录
    CsRegister = 2, -- 注册
    ScLoginSuccess = 3, -- 登录成功
    ScRegisterSuccess = 4, -- 注册成功
    ScError = 5, -- 错误消息
    CsEnterRoom = 6, -- 进入游戏
    Heartbeat = 7, -- 心跳
    PropList = 8, -- 道具列表
    ScServers = 9, -- 服务器信息
    CsCreateUnion = 10, -- 创建公会
    ScCreateUnion = 11, -- 创建公会结果
    CsJoinUnion = 12, -- 加入公会
    ScJoinUnion = 13, -- 加入公会结果
    CsQueryUnion = 14, -- 查找公会
    ScQueryUnion = 15, -- 查询结果
    ScMails = 16, -- 邮件列表
    CsMailReq = 17, -- 主动拉去未读邮件
    CsReadMail = 18, -- 读取邮件
    CsUnionInfo = 19, -- 查询公会信息
    ScUnionInfo = 20, -- 公会信息
    CsExitUnion = 21, -- 退出公会
    ScExitUnion = 22, -- 退出公会返回
    CsUnionSettings = 23, --公会设置
    CsTransferMaster = 24, -- 公会转让
    ScTransferMaster = 25,
    CsTickMember = 26, -- 踢出公会
    ScTickMember = 27,
    CsLocation = 28, -- 更新位置
    ScLocation = 29,
}

return baseid