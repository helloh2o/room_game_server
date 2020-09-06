package main

import (
	"encoding/binary"
	"flag"
	"fmt"
	"github.com/golang/protobuf/proto"
	"log"
	"net"
	"server/protobuf"
	"sync"
	"time"
)

var (
	max = flag.Int("max", 1, "-max clients")
)

func main() {
	flag.Parse()
	log.Printf("max size %d", *max)
	done := make(chan struct{})
	_ = done
	// 测试300个人，100个房间
	for i := 0; i < *max; i++ {
		time.Sleep(time.Millisecond * 200)
		go func(index int) {
			conn, err := net.Dial("tcp", "127.0.0.1:3563")
			//conn, err := net.Dial("tcp", "120.26.45.235:2563")
			if err != nil {
				panic(err)
			}
			// Hello 消息（JSON 格式）
			// 对应游戏服务器 Hello 消息结构体
			/*data := []byte(`{
				"Room": {
					"id": 1001,
					"token":"1000"
				}
			}`)*/
			enterMsg := protobuf.CsEnterRoom{}
			enterMsg.Room = "classic_ddz"
			data, err := proto.Marshal(&enterMsg)
			//fmt.Printf("%+v\n", data)
			if err != nil {
				log.Fatal(err)
			}
			// proto 网络包 =  【包大小2byte + 消息ID2byte + 消息体nbyte】
			m := make([]byte, 4+len(data))
			// 默认使用大端序
			binary.LittleEndian.PutUint16(m, uint16(len(data)+2))
			// push id=0 表示0消息进入房间
			binary.LittleEndian.PutUint16(m[2:4], uint16(6))
			copy(m[4:], data)
			// 发送消息
			conn.Write(m)
			go func() {
				time.Sleep(time.Second * 5)
				tk := time.Tick(time.Second * 5)
				for {
					<-tk
					t := protobuf.Heartbeat{}
					data, err := proto.Marshal(&t)
					if err != nil {
						log.Fatal(err)
					}
					// len + data
					m := make([]byte, 4+len(data))
					// 默认使用大端序
					binary.LittleEndian.PutUint16(m, uint16(len(data)+2))
					// push id=0 表示游戏消息
					binary.LittleEndian.PutUint16(m[2:4], uint16(7))
					copy(m[4:], data)
					// 发送消息
					conn.Write(m)
				}
			}()
			var one sync.Once
			for {
				buf := make([]byte, 1024)
				n, err := conn.Read(buf)
				if err == nil {
					fmt.Printf("client %v  received message %v \n", index, buf[:n])
					one.Do(func() {
						if n > 2 {
							len := binary.LittleEndian.Uint16(buf[:2])
							log.Printf("pkg len =%d , read len %d", len, n)
						}
						var pkg protobuf.Protocol
						err := proto.Unmarshal(buf[4:n], &pkg)
						if err != nil {
							log.Fatal(err)
						} else {
						}
					})
				} else {
					break
				}
			}
		}(i)
	}
	//time.Sleep(time.Minute)
	<-done
}
