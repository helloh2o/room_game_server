package internal

import (
	"log"
	"server/bean"
	"server/leaf/gate"
	"server/vm"
)

func init() {
	skeleton.RegisterChanRPC("NewAgent", rpcNewAgent)
	skeleton.RegisterChanRPC("CloseAgent", rpcCloseAgent)
}

func rpcNewAgent(args []interface{}) {
	a := args[0].(gate.Agent)
	_ = a
}

func rpcCloseAgent(args []interface{}) {
	a := args[0].(gate.Agent)
	d := a.UserData()
	if d != nil {
		player, ok := d.(*bean.Player)
		defer func() {
			recover()
			log.Printf("Player %s offline \n ", player.Uuid)
		}()
		// 玩家断线了发送到LUA
		if ok && player.GetRoom() != nil {
			calldata := vm.NewCallData("player_disconnect", []interface{}{player.Id}, 0)
			player.GetRoom().VM.CallChan <- calldata
			bean.HandleResult(calldata.Result, 0)
		}
	}
}
