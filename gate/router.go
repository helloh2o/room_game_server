package gate

import (
	"github.com/golang/protobuf/proto"
	"server/game"
	"server/hall"
	"server/leaf/gate"
	"server/leaf/log"
	"server/msg"
	"server/protobuf"
)

// heartbeat
var hb proto.Message

func init() {
	// game
	msg.Processor.SetRouter(&protobuf.Protocol{}, game.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsEnterRoom{}, game.ChanRPC)
	// hall
	msg.Processor.SetRouter(&protobuf.CsLogin{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsRegister{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsCreateUnion{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsJoinUnion{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsQueryUnion{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsMailReq{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsReadMail{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsUnionInfo{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsExitUnion{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsUnionSettings{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsTransferMaster{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsTickMember{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsLocation{}, hall.ChanRPC)
	msg.Processor.SetRouter(&protobuf.CsUnionRank{}, hall.ChanRPC)
	// hb
	hb = &protobuf.Heartbeat{}
	msg.Processor.SetHandler(hb, func(args []interface{}) {
		// ping-pong
		hb := args[0].(*protobuf.Heartbeat)
		agent := args[1].(gate.Agent)
		agent.WriteMsg(hb)
		log.Debug("Heartbeat Message.")
	})
}
