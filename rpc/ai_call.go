package rpc

import (
	"context"
	"github.com/smallnest/rpcx/client"
	"server/leaf/log"
)

func AddAI(aiserver string, args *AiJoinArs) {
	d := client.NewPeer2PeerDiscovery("tcp@"+aiserver, "")
	xclient := client.NewXClient("AI", client.Failtry, client.RandomSelect, d, client.DefaultOption)
	defer xclient.Close()
	reply := &AiReply{}
	err := xclient.Call(context.Background(), "Join", args, reply)
	if err != nil {
		log.Release("failed to call: %v", err)
	}
}
