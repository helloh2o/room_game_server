package internal

import (
	"server/bean"
	"server/conf"
	"server/global"
	"server/leaf/log"
	"server/vm"
)

var (
	// VM虚拟机
	vms = make(map[string][]*vm.VM)
	// 用户等待队列 允许未处理MAX 10000
	waitQueue = global.WaitQueue
)

func Init() {
	if conf.Server.Games == nil || len(conf.Server.Games) == 0 {
		log.Release("there is no games to be run.")
	}
	for _, game := range conf.Server.Games {
		// 开始创建对应游戏VM
		for i := 0; i < game.VmSize; i++ {
			one := vm.NewVM(game.Name, game.Root)
			if one != nil {
				log.Release("create game %s vm %s", game.Name, one.Uuid)
				if list, ok := vms[game.Name]; !ok {
					vms[game.Name] = []*vm.VM{one}
				} else {
					vms[game.Name] = append(list, one)
				}
			} else {
				log.Release("created vm failed for game %s", game.Name)
			}
		}
		log.Release("Game %s, plan to created vms %d", game.Name, game.VmSize)
		// 初始化房间个数
		initRooms(game)
	}
	go enterRoom()
}

//  初始化对应游戏房间，均匀分配到多个VM
func initRooms(game conf.Game) {
	gameVms := vms[game.Name]
	if len(gameVms) == 0 {
		log.Release("There is not VM for game %s to create room.", game.Name)
	} else {
		log.Release("init room size %d for game %s", game.Room, game.Name)
		for i := 0; i < game.Room; i++ {
			// 找到房间需要注册的虚拟机
			vmIndex := i % len(gameVms)
			target := gameVms[vmIndex]
			r := bean.NewRoom()
			r.VM = target
			// 初始化房间
			gameType := "jjddz"
			place := "jjddz_custom"
			calldata := vm.NewCallData("room_init", []interface{}{r.Uuid, r.Id, gameType, place}, 0)
			//calldata := vm.NewCallData("room_init", []interface{}{r.LogUuid, r.Id, gameType, place}, []int{vm.VM_string,vm.VM_int,vm.VM_bool})
			r.VM.CallChan <- calldata
			// 等待同步结果
			result := <-calldata.Result
			if result.Ok {
				log.Release("Game %s new room %s register to VM %s", game.Name, r.Uuid, r.VM.Uuid)
			}
		}
	}
}

// 用户排队分配房间
func enterRoom() {
	for {
		if len(waitQueue) >= 9999 {
			log.Error("========== something wrong with a big user wait queue. ========== ")
			return
		}
		waitObj := <-waitQueue
		wait := waitObj.(bean.WaitPlayer)
		log.Debug("Got A wait player from queue.")
		// find the game of vm
		vmList := vms[wait.GameName]
		if len(vmList) == 0 {
			log.Release("Player %s want to enter Game %s , but no VM for this.", wait.Player.Uuid, wait.GameName)
			for name, vl := range vms {
				log.Debug("Game %s, vm size %d", name, len(vl))
			}
			if wait.GameName == "classic_ddz" {
				log.Debug("all vms %v", vms)
			}
			continue
		}
		// find vm index for player
		vmIndex := wait.Player.Id % int64(len(vmList))
		playerVm := vmList[vmIndex]
		// init player data
		calldata := vm.NewCallData("player_init", []interface{}{wait.Player.Uuid, wait.Player.ToJson()}, 1)
		playerVm.CallChan <- calldata
		ret := <-calldata.Result
		if ret.Ok && ret.Data[0] == true {
			// call lua allocate a room for this player
			calldata = vm.NewCallData("player_enter_room", []interface{}{wait.Player.Id}, 2)
			playerVm.CallChan <- calldata
			ret := <-calldata.Result
			log.Debug("%+v", ret)
			if ret.Ok && len(ret.Data) >= 2 {
				roomId, ok := (ret.Data[0]).(int64)
				log.Debug("roomid %d, ok %v", roomId, ok)
				if ok {
					log.Debug("finding the room %v in go.", roomId)
					room, ok := global.Rooms.Load(int(roomId))
					if ok {
						log.Debug("found the room %v", roomId)
						r := room.(*bean.Room)
						wait.Player.SetRoom(r)
						// 进入房间
						r.Join(wait.Player)
						// 游戏中
						wait.Player.SetGaming(true)
						// 处理命令
						calldata.Result <- ret
						bean.HandleResult(calldata.Result, 1)
					} else {
						log.Release("not found the room by room id %v", roomId)
					}
				}
			} else {
				log.Error("enter room not enough result %d", len(ret.Data))
			}
		}
	}
}
