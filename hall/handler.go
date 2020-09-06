package hall

import (
	"reflect"
	"server/hall/login"
	"server/hall/mail"
	"server/hall/union"
	"server/protobuf"
)

func handleMsg(m interface{}, h interface{}) {
	skeleton.RegisterChanRPC(reflect.TypeOf(m), h)
}

func init() {
	// login
	handleMsg(&protobuf.CsLogin{}, login.Login)
	handleMsg(&protobuf.CsRegister{}, login.Register)
	handleMsg(&protobuf.CsLocation{}, login.UpdateLocation)
	// union
	handleMsg(&protobuf.CsCreateUnion{}, union.CreateUnion)
	handleMsg(&protobuf.CsQueryUnion{}, union.Query)
	handleMsg(&protobuf.CsJoinUnion{}, union.Join)
	handleMsg(&protobuf.CsUnionInfo{}, union.GetUnionDetail)
	handleMsg(&protobuf.CsExitUnion{}, union.Exit)
	handleMsg(&protobuf.CsUnionSettings{}, union.Settings)
	handleMsg(&protobuf.CsTransferMaster{}, union.Transfer)
	handleMsg(&protobuf.CsTickMember{}, union.TickMember)
	handleMsg(&protobuf.CsUnionRank{}, union.RankRoll)
	// email
	handleMsg(&protobuf.CsMailReq{}, mail.PullMail)
	handleMsg(&protobuf.CsReadMail{}, mail.ReadMail)
}
