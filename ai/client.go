package ai

import (
	"encoding/binary"
	"github.com/golang/protobuf/proto"
	"io"
	"net"
	"server/bean"
	"server/encrypt"
	"server/leaf/log"
	"server/msg"
	"server/protobuf"
)

type Client struct {
	Conn      net.Conn
	Player    *bean.Player
	OnPackage chan []byte
	Done      chan struct{}
	GameInfo  *ScStartGame
	Notify    *ScGameActionNotify
	Dizhu     int32
}

func NewClient(c net.Conn) *Client {
	client := new(Client)
	client.Conn = c
	p := getAi()
	if p == nil {
		return nil
	}
	client.Player = p
	client.Done = make(chan struct{})
	client.OnPackage = make(chan []byte)
	return client
}

func (c *Client) Start(r, p string) {
	go c.read()
	go c.handle()
	// 发送第一个消息
	if r == "" && p == "" {
		r = "classic_ddz"
		p = "custom"
	}
	enter := protobuf.CsEnterRoom{
		Player: c.Player.ToJson(),
		Room:   r,
		Place:  p,
	}

	bs, err := proto.Marshal(&enter)
	if err != nil {
		log.Error("Marshal enter error %v", err)
	} else {
		c.write(msg.CsEnterRoom, bs)
	}
}

func (c *Client) write(id int, data []byte) {
	m := make([]byte, 4+len(data))
	binary.LittleEndian.PutUint16(m, uint16(len(data)+2))
	binary.LittleEndian.PutUint16(m[2:4], uint16(id))
	copy(m[4:], data)
	encrypt.CipherX.Encode(m[2:])
	n, err := c.Conn.Write(m)
	if err != nil || n != len(m) {
		log.Error("Write package error %s %d", err, n)
	}
}

func (c *Client) read() {
	defer func() {
		c.Done <- struct{}{}
	}()
	for {
		lenSlice := make([]byte, 2)
		_, err := io.ReadFull(c.Conn, lenSlice)
		if err != nil {
			log.Debug("Client Read msg length error %v", err)
			break
		}
		length := binary.LittleEndian.Uint16(lenSlice)
		pk := make([]byte, length)
		_, err = io.ReadFull(c.Conn, pk)
		if err != nil {
			log.Debug("Client Read package error %v", err)
			break
		}
		encrypt.CipherX.Decode(pk)
		c.OnPackage <- pk
	}
}

func (c *Client) handle() {
	for {
		select {
		case pk := <-c.OnPackage:
			//log.Debug("LittleEndianackage %+v", pk)
			id := binary.LittleEndian.Uint16(pk[:2])
			data := pk[2:]
			// 解包
			switch id {
			case 0:
				var p protobuf.Protocol
				err := proto.Unmarshal(data, &p)
				if err != nil {
					log.Error("unmarshal error %v", err)
				} else {
					c.doLogic(&p)
				}
			case 1:

			}
		case <-c.Done:
			putAi(c.Player)
			return
		}
	}
}
