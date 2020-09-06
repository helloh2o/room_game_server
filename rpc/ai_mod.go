package rpc

type AiJoinArs struct {
	Server    string // 连接的游戏服务器
	GameName  string // 游戏名字  //classic_ddz
	GamePlace string // 游戏场次
}

type AiReply struct {
	OK     bool
	Reason string
}
