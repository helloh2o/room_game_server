package bean

import (
	"fmt"
	"server/leaf/log"
	"server/vm"
	"sync"
	"time"
)

var TB = TimerBucket{}

func init() {
	go TB.Run()
}

type TimerBucket struct {
	timers sync.Map
}

func (tb *TimerBucket) Add(t *GameTimer) {
	key := fmt.Sprint(t.RoomId, "-", t.Id, "-", t.Tag)
	log.Debug("Add timer key %s to run %+v", key, *t)
	tb.timers.Store(key, t)
}

func (tb *TimerBucket) Kill(cmd *TimerCommand) {
	key := fmt.Sprint(cmd.RoomId, "-", cmd.TimerId, "-", cmd.Tag)
	gt, ok := tb.timers.Load(key)
	if ok {
		gt, ok := gt.(*GameTimer)
		if ok {
			gt.T.Stop()
			tb.remove(key)
		}
	} else {
		log.Release("Not found the game timer %s", key)
	}
}

func (tb *TimerBucket) remove(key string) {
	tb.timers.Delete(key)
	log.Release("Removed timer %s", key)
}

func (tb *TimerBucket) Run() {
	defer func() {
		if r := recover(); r != nil {
			log.Debug("TimerBucket Crashed %v", r)
		}
	}()
	for {
		tb.timers.Range(func(key, value interface{}) bool {
			gt, ok := value.(*GameTimer)
			if ok {
				select {
				// on timer
				case <-gt.T.C:
					call(gt)
					//log.Println("on call")
					key := fmt.Sprint(gt.RoomId, "-", gt.Id, "-", gt.Tag)
					// remove
					tb.remove(key)
				default:
					return true
				}
			}
			return true
		})
		time.Sleep(time.Millisecond * 50)
	}
}

func call(gt *GameTimer) {
	calldata := vm.NewCallData("on_timer", []interface{}{gt.RoomId, gt.Id, gt.Tag}, 0)
	gt.VM.CallChan <- calldata
	HandleResult(calldata.Result, 0)
}
