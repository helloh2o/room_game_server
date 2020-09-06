package bean

import (
	"server/vm"
	"time"
)

type GameTimer struct {
	Id       int           // 计时器ID
	RoomId   int           // 房间号
	Tag      string        // 标签
	Duration time.Duration // 持续时间，秒
	T        *time.Timer
	VM       *vm.VM
}
