package msg

import (
	"server/leaf/network/protobuf"
	pp "server/protobuf"
)

var Processor = protobuf.NewProcessor()

func init() {
	Processor.Register(&pp.Protocol{})          //0
	Processor.Register(&pp.CsLogin{})           //1
	Processor.Register(&pp.CsRegister{})        //2
	Processor.Register(&pp.ScLoginSuccess{})    //3
	Processor.Register(&pp.ScRegisterSuccess{}) //4
	Processor.Register(&pp.ScError{})           //5
	Processor.Register(&pp.CsEnterRoom{})       //6
	Processor.Register(&pp.Heartbeat{})         //7
	Processor.Register(&pp.ScPropList{})        //8
	Processor.Register(&pp.ScServers{})         //9
	Processor.Register(&pp.CsCreateUnion{})     //10
	Processor.Register(&pp.ScCreateUnion{})     //11
	Processor.Register(&pp.CsJoinUnion{})       //12
	Processor.Register(&pp.ScJoinUnion{})       //13
	Processor.Register(&pp.CsQueryUnion{})      //14
	Processor.Register(&pp.ScQueryUnion{})      //15
	Processor.Register(&pp.ScMails{})           //16
	Processor.Register(&pp.CsMailReq{})         //17
	Processor.Register(&pp.CsReadMail{})        //18
	Processor.Register(&pp.CsUnionInfo{})       //19
	Processor.Register(&pp.ScUnionInfo{})       //20
	Processor.Register(&pp.CsExitUnion{})       //21
	Processor.Register(&pp.ScExitUnion{})       //22
	Processor.Register(&pp.CsUnionSettings{})   //23
	Processor.Register(&pp.CsTransferMaster{})  //24
	Processor.Register(&pp.ScTransferMaster{})  //25
	Processor.Register(&pp.CsTickMember{})      //26
	Processor.Register(&pp.ScTickMember{})      //27
	Processor.Register(&pp.CsLocation{})        //28
	Processor.Register(&pp.ScLocation{})        //29
	Processor.Register(&pp.CsUnionRank{})       //30
	Processor.Register(&pp.ScUnionRank{})       //31

}

const (
	Protocol = iota
	CsLogin
	CsRegister
	ScLoginSuccess
	ScRegisterSuccess
	ScError
	CsEnterRoom
	Heartbeat
	ScPropList
	ScServers
	CsCreateUnion
	ScCreateUnion
	CsJoinUnion
	ScJoinUnion
	CsQueryUnion
	ScQueryUnion
	ScMails
	CsMailReq
	CsReadMail
	CsUnionInfo
	ScUnionInfo
	CsExitUnion
	ScExitUnion
	CsUnionSettings
	CsTransferMaster
	ScTransferMaster
	CsTickMember
	ScTickMember
	CsLocation
	ScLocation
	CsUnionRank
	ScUnionRank
)
