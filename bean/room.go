package bean

import (
	"github.com/google/uuid"
	"runtime/debug"
	"server/global"
	"server/leaf/log"
	"server/msg"
	"server/protobuf"
	"server/vm"
	"sync"
	"sync/atomic"
)

type Room struct {
	Id      int
	lk      sync.RWMutex
	Uuid    string
	Players map[string]*Player // 房间里的用户
	VM      *vm.VM             // 虚拟机
	RoomIn  chan Msg           // 消息进入通道
	Close   chan struct{}      // 关闭房间通道
	Gaming  bool               // 游戏中
}

var roomid int64

func NewRoom() *Room {
	room := new(Room)
	room.Id = int(atomic.AddInt64(&roomid, 1))
	room.Uuid = uuid.New().String()
	room.Close = make(chan struct{}, 1)
	room.Players = make(map[string]*Player)
	room.RoomIn = make(chan Msg)
	// 保存全局变量
	global.Rooms.Store(room.Id, room)
	global.Rooms.Store(room.Uuid, room)
	// 监听和接受房间消息
	go room.run()
	return room
}

func (r *Room) Join(player *Player) {
	r.lk.Lock()
	defer r.lk.Unlock()
	r.Players[player.Uuid] = player
}

func (r *Room) Leave(player *Player) {
	log.Debug("remove player conn, remove player in room status")
	r.lk.Lock()
	defer r.lk.Unlock()
	player.SetRoom(nil)
	delete(r.Players, player.Uuid)
}

func (r *Room) run() {
	defer func() {
		log.Release(" =========== Room Run End ============")
		if r := recover(); r != nil {
			log.Error("Crash in Room run() %s\n", debug.Stack())
		}
		r.kickOut()
	}()
	// 房间
	for {
		select {
		case m := <-r.RoomIn:
			var datap []byte
			if m.Raw != nil {
				datap = m.Raw
				log.Debug("Raw data from client %+v", m.Raw)
				// call onmessage
				datastr := string(datap)
				log.Debug("onmessage data string =(%s) length=%d", datastr, len(datastr))
				calldata := vm.NewCallData("onmessage", []interface{}{m.Player.Id, datastr}, 2)
				r.VM.CallChan <- calldata
				HandleResult(calldata.Result, 0)
			} else {
				log.Release("No raw data error msg.")
			}
		case <-r.Close:
			return
		}
	}
}

func (r *Room) kickOut() {
	action := &protobuf.Protocol{Id: msg.G_kickout_room}
	// 踢出玩家
	for _, p := range r.Players {
		r.Leave(p)
		// 踢出玩家
		p.Agent().WriteMsg(action)
	}
}

func (r *Room) GetVm() *vm.VM {
	return r.VM
}
