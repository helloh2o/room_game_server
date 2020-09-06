package bean

// LUA 返回指令
/*type Commands []Command
type Command []string //[0] send [1] detail
type Detail []string //
*/

type Command interface {
	cmd()
}

type SendCommand struct {
	Name     string
	Player   string
	Packages [][]byte
}

type TimerCommand struct {
	Name     string
	RoomId   int
	TimerId  int
	Duration int
	Tag      string
}

type UpdateCommand struct {
	Name       string
	UpdateInfo []map[string]interface{}
}

type WriteCommand struct {
	UuidArr []string
}

type ClosePCommand struct {
	pid    string
	reason string
}

type AddBotCommand struct {
	game string
}

type AddLogCommand struct {
	glog *GameLog
	ulog []*UserLog
}

func (c *UpdateCommand) cmd() {}
func (c *TimerCommand) cmd()  {}
func (c *SendCommand) cmd()   {}
func (c *WriteCommand) cmd()  {}
func (c *ClosePCommand) cmd() {}
func (c *AddBotCommand) cmd() {}
func (c *AddLogCommand) cmd() {}
