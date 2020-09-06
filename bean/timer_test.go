package bean

import (
	"github.com/gogo/protobuf/proto"
	"server/leaf/log"
	"server/protobuf"
	"server/vm"
	"testing"
	"time"
)

func TestTimerBucket_Add(t *testing.T) {
	v := vm.NewVM("ddz", "D:/gohub/src/server/lua/game/test_game/root.lua")
	// 启动
	go v.Run()
	r := NewRoom()
	r.VM = v
	// 初始化房间
	gameType := "jjddz"
	place := "jjddz_custom"
	calldata := vm.NewCallData("room_init", []interface{}{r.Uuid, r.Id, gameType, place}, 0)
	//calldata := vm.NewCallData("room_init", []interface{}{r.Uuid, r.Id, gameType, place}, []int{vm.VM_string,vm.VM_int,vm.VM_bool})
	r.VM.CallChan <- calldata
	// 等待同步结果
	result := <-calldata.Result
	if result.Ok {
		log.Release("Game jjddz new room %s register to VM %s", r.Uuid, r.VM.Uuid)
	}
	for i := 0; i < 10; i++ {
		time.Sleep(time.Second * time.Duration(i))
		/*go func() {
			gt := GameTimer{
				Duration: 3,
				Id:       i,
			}
			gt.T = time.NewTimer(time.Second * gt.Duration)
			bucket.Add(&gt)
		}()*/
		p := &protobuf.Protocol{Id: 1001}
		data, _ := proto.Marshal(p)
		calldata := vm.NewCallData("onmessage", []interface{}{string(data), "xx"}, 5)
		v.CallChan <- calldata
		// 等待同步结果
		// 0 is A Table
		HandleResult(calldata.Result, 0)
	}
	time.Sleep(time.Hour * 10)
}
