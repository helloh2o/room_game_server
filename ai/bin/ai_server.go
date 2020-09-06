package main

import (
	"flag"
	"github.com/smallnest/rpcx/server"
	"log"
	"net"
	"server/ai"
	"server/encrypt"
	"time"
)

var (
	max        = flag.Int("max", 3, "max ai client")
	serverAddr = flag.String("server", "120.26.45.235:3563", "game server addr")
	listenAddr = flag.String("listen", ":7080", "open for call AI address.")
	autoPlay   = flag.Bool("auto", true, "all robot auto play on server started.")
)

func main() {
	flag.Parse()
	ai.Init(*max)
	ai.InitPlayRule()
	// 初始化加密
	encrypt.InitCipher("TH27Cco/KLPtga3Z1BLMNwTaEXp/B8GnLQpKbkKk8esx6qCIQ1eYdPdfDizG+WxG04lSpfXXry8c2+OHgqxEOSGqiimMsMCE/1tt/Ku0SLqT5Hj2n949yx7VaQvyNR+5WWjNoVMVg6Ps9BtkeeDPDb1rIvMgjXJ274DfcE1OkPg4JLyuycMyGvvlXkDuhp0CsjTdECNdd9E6HUlab0VznjZnqbEnXP3pjqjQaoXc1lQ7YSqm5mPIPNKUi3szDMecAxf6AVYUvxkrPpVPWAi1msX+Zrh8AC6bSxhR6MThfo/YBSVBBufCJs4wFpJHl2K3ZQ/wdb5gouITUJGWmVW2cQ==")
	// 所有机器人自动跑
	if *autoPlay {
		for i := 1; i <= *max; i++ {
			c, err := net.Dial("tcp", *serverAddr)
			if err != nil {
				log.Printf("can't dial server %s, err %v", *serverAddr, err)
				break
			}
			client := ai.NewClient(c)
			go client.Start("", "")
			time.Sleep(time.Millisecond * 100)
		}
	} else {
		// RUN RPC CALL server, I need an AI player
		s := server.NewServer()
		err := s.RegisterName("AI", new(ai.AICall), "")
		if err != nil {
			log.Fatal(err)
		} else {
			go func() {
				err := s.Serve("tcp", *listenAddr)
				if err != nil {
					log.Fatal(err)
				}
			}()
		}
	}
	select {}
}
