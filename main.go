package main

import (
	"fmt"
	"io/ioutil"
	LG "log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"runtime"
	"server/conf"
	"server/db"
	"server/encrypt"
	"server/game"
	"server/gate"
	"server/hall"
	"server/httpsv"
	"server/leaf"
	lconf "server/leaf/conf"
	"server/leaf/log"
)

func main() {
	lconf.LogLevel = conf.Server.LogLevel
	lconf.LogPath = conf.Server.LogPath
	lconf.LogFlag = conf.LogFlag
	lconf.ConsolePort = conf.Server.ConsolePort
	lconf.ProfilePath = conf.Server.ProfilePath
	// 初始化数据库
	db.PGRun()
	// 初始化游戏，虚拟机，房间
	game.Init()
	// 初始化加密暗哨
	encrypt.InitCipher(conf.Server.EncryptStr)
	// pprof
	go func() {
		runtime.GOMAXPROCS(2)              // 限制 CPU 使用数，避免过载
		runtime.SetMutexProfileFraction(1) // 开启对锁调用的跟踪
		runtime.SetBlockProfileRate(1)     // 开启对阻塞操作的跟踪
		http.ListenAndServe("0.0.0.0:6060", nil)
	}()
	// http server
	go httpsv.RunHTTP(conf.Server.HTTPAddr)
	log.Release("Websocket on => %s", conf.Server.WSAddr)
	log.Release("TCP on => %s", conf.Server.TCPAddr)
	pid := os.Getpid()
	log.Release("Process ID %d", pid)
	err := ioutil.WriteFile("shutdown.sh", []byte(fmt.Sprintf("kill %d", pid)), os.ModePerm)
	if err != nil {
		log.Error("create shutdown.sh failed.")
	}
	leaf.Run(
		new(hall.Module),
		game.Module,
		gate.Module,
	)
	// 写库
	db.OnFinalSave <- struct{}{}
	<-db.Done
	LG.Println("Server is shutdown.")
}
