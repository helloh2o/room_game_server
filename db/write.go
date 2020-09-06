package db

import (
	"log"
	"runtime"
	"server/global"
	LG "server/leaf/log"
	"time"
)

// 处理写库
var (
	// 服务器关闭，最后一次写库
	OnFinalSave = make(chan struct{})
	// 手动强制存盘
	OnForceSave = make(chan struct{})
	// 定时存盘需要存储的用户 Timer 30分钟
	timerSave = time.NewTicker(time.Minute * 30)
	// 结束
	Done = make(chan struct{})
)

func init() {
	go func() {
		var gss global.SingleSave
		var err error
		defer func() {
			if r := recover(); r != nil {
				var buf [4096]byte
				n := runtime.Stack(buf[:], false)
				log.Printf("Panic Stack, %v", string(buf[:n]))
				log.Printf("Panic error %v", err)
				if len(gss.Err) == 0 {
					gss.Err <- err
				}
			}
			Done <- struct{}{}
		}()
		for {
			select {
			case gss = <-global.OnSingleSave:
				switch gss.Type {
				case 1:
					log.Println("DB writer do single save.")
					err = Save(gss.Data)
				case 2:
					log.Println("DB writer do InsertMulti save.")
					err = InsertMulti(gss.Length, gss.Data)
				default:
					log.Println("DB writer do Update save.")
					err = Update(gss.Data)
				}
				if err != nil {
					LG.Release("save error %s OnSingleSave", err.Error())
				}
				// 返回结果
				gss.Err <- err
			case <-timerSave.C:
				log.Printf("DB writer do timer save.")
				doUpdate()
			case <-OnForceSave:
				doUpdate()
			case <-OnFinalSave:
				log.Printf("DB writer do final save.")
				doUpdate()
				return
			}
		}
	}()
}

func doUpdate() {
	defer func() {
		recover()
	}()
	global.WaitUpdates.Range(func(key, obj interface{}) bool {
		err := Update(obj)
		if err != nil {
			LG.Release("update error %s Object %+v", err.Error(), obj)
		} else {
			// delete wait update
			global.WaitUpdates.Delete(key)
		}
		return true
	})
}
