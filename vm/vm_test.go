package vm

import (
	"github.com/golang/protobuf/proto"
	"log"
	"server/protobuf"
	"sync"
	"testing"
	"time"
)

func TestNewVM(t *testing.T) {
	// 模拟客户端N
	clients := 5000
	// 单个客户端Call VM 次数
	clientCallTimes := 30
	// VM 数量
	vmsize := 1
	vms := make([]*VM, 0)
	for i := 0; i < vmsize; i++ {
		vm := NewVM("ddz", "D:/gohub/src/server/lua/game/test_game/root.lua")
		if vm != nil {
			vms = append(vms, vm)
		}
	}
	max := clients
	var wg sync.WaitGroup
	wg.Add(clients)
	start := time.Now().Unix()
	// 外部调用， 是否同步
	for i := 0; i < clients; i++ {
		// 多个goroutine 调用
		go func(index int) {
			defer func() {
				wg.Done()
			}()
			p := &protobuf.Protocol{Id: 1001}
			data, _ := proto.Marshal(p)
			calltimes := 0
			for calltimes < clientCallTimes {
				calldata := NewCallData("onmessage", []interface{}{string(data), "xx"}, 1)
				vindex := index % len(vms)
				log.Printf("vm index %d", vindex)
				vm := vms[vindex]
				vm.CallChan <- calldata
				// 等待同步结果
				result := <-calldata.Result
				log.Printf("Caller %d Result %v Times %d", index, result, calltimes)
				calltimes++
			}
		}(i)
	}
	wg.Wait()
	end := time.Now().Unix()
	log.Printf("%d  clients  %d call times, costs %d s", max, max*clientCallTimes, end-start)
}
