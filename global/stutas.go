package global

import (
	"sync"
)

// 全局状态
var (
	// 用户与映射
	Players = sync.Map{}
	// 房间映射
	Rooms = sync.Map{}
	// 有数据发生变化的用户
	WaitUpdates = sync.Map{}
	// 指定存储某对象
	OnSingleSave = make(chan SingleSave)
	// 等待队列
	WaitQueue = make(chan interface{}, 10000)
)

// 单个保存
type SingleSave struct {
	// 数据
	Data interface{}
	// 错误
	Err chan error
	// 类型 0 update // 1 insert []interface{} // 2 insert obj
	Type int
	// 数量
	Length int
}
