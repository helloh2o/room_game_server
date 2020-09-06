package ai

import (
	"context"
	"log"
	"net"
	"server/rpc"
)

type AICall struct {
}

// 远程调用，加入一个机器人到指定服务器对应游戏的场次中
func (ac *AICall) Join(ctx context.Context, args *rpc.AiJoinArs, reply *rpc.AiReply) error {
	c, err := net.Dial("tcp", args.Server)
	if err != nil {
		log.Printf("can't dial server %s, err %v", args.Server, err)
		return err
	}
	client := NewClient(c)
	go client.Start(args.GameName, args.GamePlace)
	return nil
}
