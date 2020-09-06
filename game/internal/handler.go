package internal

import (
	"encoding/json"
	"reflect"
	"runtime/debug"
	"server/bean"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/protobuf"
	"server/vm"
	"strings"
)

func handleMsg(m interface{}, h interface{}) {
	skeleton.RegisterChanRPC(reflect.TypeOf(m), h)
}
func init() {
	handleMsg(&protobuf.Protocol{}, doGame)
	handleMsg(&protobuf.CsEnterRoom{}, matchRoom)
}

var id int64

// 进入房间
func matchRoom(args []interface{}) {
	log.Debug("On enter room message")
	info := args[0].(*protobuf.CsEnterRoom)
	agent := args[1].(gate.Agent)
	d := agent.UserData()
	var player *bean.Player
	if d != nil {
		// 连接上的引用
		player = d.(*bean.Player)
	}
	// 不存在，去cache找
	if player == nil && info.Player != "" {
		// 如果Player是JSON 开头，机器人进入
		if strings.Contains(string(info.Player[0]), "{") {
			err := json.Unmarshal([]byte(info.Player), &player)
			if err != nil {
				log.Error("Unmarshal Player from CsEnterRoom.Player error %s", info.Player)
			}
		} else { // info.Player 为UUID
			// find in cache
			gp, e := global.Players.Load(info.Player)
			if e {
				player = gp.(*bean.Player)
			}
		}
	}
	if player != nil {
		player.SetAgent(agent)
		agent.SetUserData(player)
		global.Players.Store(player.Uuid, player)
		if player.GetRoom() == nil {
			log.Debug("Put in waitQueue")
			// 放进用户队列
			waitQueue <- bean.WaitPlayer{
				Player:   player,
				GameName: info.Room,
			}
		} else {
			log.Debug("do player_continue_game")
			// player_continue_game 重连
			calldata := vm.NewCallData("player_continue_game", []interface{}{player.Id, player.GetRoom().Id}, 0)
			player.GetRoom().VM.CallChan <- calldata
			bean.HandleResult(calldata.Result, 0)
		}
	} else {
		log.Debug("Not found the player, %s", info.Player)
		agent.WriteMsg(&protobuf.ScError{Code: -1, Reason: "错误，需要重新登录。"})
	}

}

func doGame(args []interface{}) {
	defer func() {
		if r := recover(); r != nil {
			log.Error("do game message error, %s", debug.Stack())
		}
	}()
	log.Debug("Args size %d", len(args))
	var raw []byte
	if len(args) >= 3 {
		raw = args[2].([]byte)
		log.Debug("Mesage Raw %+v", raw)
		agent := args[1].(gate.Agent)
		var player *bean.Player
		d := agent.UserData()
		if d != nil {
			var ok bool
			player, ok = d.(*bean.Player)
			if !ok {
				log.Release("not found player on agent")
				return
			}
			if player.GetRoom() != nil {
				player.GetRoom().RoomIn <- bean.Msg{player, raw}
			} else {
				log.Release("player not in room")
			}
		}
	} else {
		log.Error("No raw data message")
	}
}
