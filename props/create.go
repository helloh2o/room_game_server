package props

import "time"

func NewProp(Pid int, player string, size int, day int64) *Prop {
	prop := new(Prop)
	prop.PID = Pid
	prop.Player = player
	prop.Size = size
	if day > 0 {
		prop.LimitTime = time.Now().Unix() + (day * 24 * 60 * 60)

	}
	return prop
}
