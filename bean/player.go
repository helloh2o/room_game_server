package bean

import (
	"encoding/json"
	"server/leaf/gate"
	"server/props"
	"sync"
)

type Player struct {
	lk        sync.RWMutex  `json:"-" orm:"-"`
	Id        int64         `json:"oid"`
	Uuid      string        `json:"uuid" orm:"unique;index"`
	NickName  string        `json:"nick_name"`
	Name      string        `json:"name" orm:"unique;index"`
	Password  string        `json:"-"`
	Gold      int64         `json:"gold"`
	Coin      int64         `json:"coin"`
	RoomCard  int64         `json:"room_card"`
	Sex       int           `json:"sex"`
	Ver       string        `json:"ver"`
	Exp       int64         `json:"exp"`
	Channel   string        `json:"channel"`
	Phone     string        `json:"phone" orm:"unique;index"`
	Device    string        `json:"device" orm:"unique;index"`
	Email     string        `json:"email" orm:"unique;index"`
	LastLogin int64         `json:"last_login"`
	Ip        string        `json:"ip"`
	Token     string        `json:"token"`
	Head      string        `json:"head"`
	agent     gate.Agent    `json:"-" orm:"-"`
	Room      *Room         `json:"-" orm:"-"`
	Props     []*props.Prop `json:"props" orm:"-"`
	Gaming    bool          `json:"-"`
	Robot     bool          `json:"robot"`
	Union     int64         `json:"union" orm:"unique;index"` // 区域，公会划分
	Level     int64         `json:"level"`                    // 等级
	UnionVal  int64         `json:"union_val"`                // 公会贡献值
	Location  string        `json:"location"`                 // 位置
}

func (p *Player) ToJson() string {
	data, err := json.Marshal(p)
	if err != nil {
		return "{'err':'-1'}"
	}
	return string(data)
}
func (p *Player) SetAgent(a gate.Agent) {
	p.lk.Lock()
	defer p.lk.Unlock()
	p.agent = a
}

func (p *Player) Agent() gate.Agent {
	p.lk.Lock()
	defer p.lk.Unlock()
	return p.agent
}

func (p *Player) SetRoom(r *Room) {
	p.lk.Lock()
	defer p.lk.Unlock()
	p.Room = r
}

func (p *Player) GetRoom() *Room {
	p.lk.Lock()
	defer p.lk.Unlock()
	return p.Room
}

func (p *Player) SetGaming(in bool) {
	p.lk.Lock()
	defer p.lk.Unlock()
	p.Gaming = in
}

func (p *Player) GetGaming() bool {
	p.lk.Lock()
	defer p.lk.Unlock()
	return p.Gaming
}

type WaitPlayer struct {
	Player   *Player
	GameName string
}
