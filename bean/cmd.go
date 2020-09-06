package bean

import (
	"github.com/golang/protobuf/proto"
	"runtime/debug"
	"server/conf"
	"server/global"
	"server/interface"
	"server/leaf/log"
	"server/protobuf"
	"server/rpc"
	"server/vm"
	"time"
)

//[["send",["25a72866-e35e-44bf-9468-adac68955a6d","\u0012\t\u0012\u0007\u0012\u0002\u0010\u0002\b\"\bþ#"]]]
//[["send",["60de37ac-176b-4cd4-a8ac-41b652aee82a",[{"content":"\u0010\u0001","id":4353}]]]]
func HandleResult(callResult chan vm.CallResult, dataIndex int) {
	result := <-callResult
	if result.Ok && len(result.Data) > 0 {
		luaTable := result.Data[dataIndex]
		cmds := make([]Command, 0)
		defer func() {
			if r := recover(); r != nil {
				log.Release("ParseCommands panic %v %s", r, debug.Stack())
			}
			//do cmd
			if cmds != nil && len(cmds) > 0 {
				for _, c := range cmds {
					switch c.(type) {
					// 发送消息
					case *SendCommand:
						doSendCommand(c)
					case *TimerCommand:
						doTimerCommand(c)
					case *UpdateCommand:
						doUpdateCommand(c)
					case *WriteCommand:
						doWriteCommand(c)
					case *ClosePCommand:
						doClosePlayerCommand(c)
					case *AddBotCommand:
						doAddBotCommand(c)
					case *AddLogCommand:
						go doAddLogCommand(c)
					}
				}
			}
		}()
		value, ok := luaTable.([]interface{})
		if !ok {
			log.Release("luaTable is not a command list. %v", luaTable)
			return
		}
		for _, v := range value {
			per, ok := v.([]interface{})
			if ok {
				name, ok := per[0].(string)
				if ok {
					switch {
					case name == "send":
						cmd := SendCommand{Name: name}
						detail, ok := per[1].([]interface{})
						if ok {
							player, ok := detail[0].(string)
							if ok {
								cmd.Player = player
								pkgs, ok := detail[1].(string)
								if ok {
									data := []byte(pkgs)
									// 尝试解析回发的消息
									log.Debug("Got send content bytes %v", pkgs)
									var p protobuf.Protocol
									err := proto.Unmarshal(data, &p)
									if err != nil {
										log.Error("proto.Unmarshal error %v", err)
									} else {
										log.Debug("%+v", data)
										log.Debug("pid=%v, content=%v", p.Id, p.Content)
									}
									cmd.Packages = append(cmd.Packages, data)
									cmds = append(cmds, &cmd)
								}
							}
						}
					case name == "start_timer" || name == "kill_timer":
						cmd := TimerCommand{Name: name}
						detail, ok := per[1].([]interface{})
						if ok {
							if cmd.Name == "start_timer" && len(detail) >= 3 {
								cmd.RoomId = int(detail[0].(int64))
								cmd.TimerId = int(detail[1].(int64))
								cmd.Duration = int(detail[2].(int64))
								cmd.Tag = detail[3].(string)
								cmds = append(cmds, &cmd)
							} else if cmd.Name == "kill_timer" && len(detail) >= 2 {
								cmd.RoomId = int(detail[0].(int64))
								cmd.TimerId = int(detail[1].(int64))
								cmd.Tag = detail[2].(string)
								cmds = append(cmds, &cmd)
							}
						}
					case name == "update_user_info": // 更新 用户数据
						cmd := UpdateCommand{Name: name, UpdateInfo: make([]map[string]interface{}, 0)}
						detail, ok := per[1].([]interface{})
						if ok {
							for _, data := range detail {
								per := data.(map[string]interface{})
								cmd.UpdateInfo = append(cmd.UpdateInfo, per)
							}
							cmds = append(cmds, &cmd)
						}
					case name == "write_user_info":
						cmd := WriteCommand{make([]string, 0)}
						detail, ok := per[1].([]interface{})
						if ok {
							for _, data := range detail {
								uuid, ok := data.(string)
								if ok {
									cmd.UuidArr = append(cmd.UuidArr, uuid)
								}
							}
							cmds = append(cmds, &cmd)
						}
					case name == "close_player":
						cmd := ClosePCommand{}
						detail, ok := per[1].([]interface{})
						if ok {
							uuid, ok := detail[0].(string)
							if ok {
								cmd.pid = uuid
							}
							// message
							message, ok := detail[1].(string)
							if ok {
								cmd.reason = message
							}
							cmds = append(cmds, &cmd)
						}
					case name == "add_bot":
						cmd := AddBotCommand{}
						gameName, ok := per[1].(string)
						if ok {
							cmd.game = gameName
							cmds = append(cmds, &cmd)
						}
					case name == "log_sql":
						glog := new(GameLog)
						detail, ok := per[1].([]interface{})
						if ok {
							glog.GroupId, _ = detail[0].(string)
							glog.LogUuid, _ = detail[1].(string)
							glog.GameType, _ = detail[2].(string)
							glog.RoomPwd, _ = detail[3].(string)
							glog.LogData, _ = detail[4].(string)
							glog.BeginTime, _ = detail[5].(int64)
							//glog.RoomUuid, _ = detail[6].(string)
							logcmd := &AddLogCommand{glog: glog, ulog: make([]*UserLog, 0)}
							// users
							Ids, ok := per[2].([]interface{})
							if ok {
								for _, id := range Ids {
									l := new(UserLog)
									l.LogUuid = glog.LogUuid
									l.PlayerId = id.(int64)
									l.AddTime = time.Now().Unix()
									logcmd.ulog = append(logcmd.ulog, l)
								}
							} else {
								log.Error("No user ids.")
							}
							cmds = append(cmds, logcmd)
						}
					default:
						log.Release("unhandle command name %s", name)
					}
				}
			}
		}
	} else {
		log.Error("unexpected handle result. %+v", result)
	}
}

func doTimerCommand(c interface{}) {
	log.Debug("Timer command %+v", c)
	timerCmd := c.(*TimerCommand)
	switch timerCmd.Name {
	case "start_timer":
		room, ok := global.Rooms.Load(timerCmd.RoomId)
		if ok {
			room := room.(interfaces.VRoom)
			gt := GameTimer{
				Id:       timerCmd.TimerId,
				RoomId:   timerCmd.RoomId,
				Duration: time.Second * time.Duration(timerCmd.Duration),
				VM:       room.GetVm(),
				Tag:      timerCmd.Tag,
			}
			gt.T = time.NewTimer(gt.Duration)
			TB.Add(&gt)
		}
	case "kill_timer":
		TB.Kill(timerCmd)
	}
}

// 执行 发送命令
func doSendCommand(c interface{}) {
	log.Debug("发送命令，转发LUA消息")
	sendcmd := c.(*SendCommand)
	// find player
	p, ok := global.Players.Load(sendcmd.Player)
	if ok {
		p := p.(*Player)
		if len(sendcmd.Packages) > 0 {
			if p.Agent() != nil { // 排除机器人
				p.Agent().WriteRawMsg(sendcmd.Packages)
				log.Debug("write %d package to player %s", len(sendcmd.Packages), p.Uuid)
			}
		}
	} else {
		log.Release("not found the player::%s", sendcmd.Player)
	}
}

func doUpdateCommand(c interface{}) {
	cmd := c.(*UpdateCommand)
	log.Debug("执行Update命令 %+v", cmd)
	for _, updateInfo := range cmd.UpdateInfo {
		var player *Player
		var ok bool
		pid, ok := updateInfo["pid"]
		if ok {
			gp, ok := global.Players.Load(pid)
			if ok {
				player = gp.(*Player)
			}
		}
		if player != nil {
			keys := make([]string, 0)
			// update go cache global player clos
			for k, _ := range updateInfo {
				switch k {
				case "pid":
					continue
				case "gold":
					player.Gold = updateInfo[k].(int64)
				case "exp":
					player.Exp = updateInfo[k].(int64)
				}
				keys = append(keys, k)
			}
			// cache changed data
			global.WaitUpdates.Store(player.Uuid, player)
		} else {
			log.Error("Update error not found the player %s", pid)
		}
	}
}

func doWriteCommand(c interface{}) {
	cmd := c.(*WriteCommand)
	for _, uuid := range cmd.UuidArr {
		obj, ok := global.Players.Load(uuid)
		if ok {
			gss := global.SingleSave{
				Data: obj,
				Err:  make(chan error, 1),
			}
			select {
			case global.OnSingleSave <- gss:
				err := gss.Err
				if err != nil {
					log.Error("doWriteCommand DB error %v", err)
				}
			default:
				log.Error("=============================================================================")
				log.Error("doWriteCommand error, global.OnSingleSave maybe full %d or very slow to save.", len(global.OnSingleSave))
				log.Error("=============================================================================")
			}
		} else {
			log.Error("Not found write player uuid %s in global.", uuid)
		}
	}
}

func doClosePlayerCommand(c interface{}) {
	cmd := c.(*ClosePCommand)
	log.Debug("call doClosePlayerCommand , player uuid %s", cmd.pid)
	// find player
	gp, ok := global.Players.Load(cmd.pid)
	if ok {
		player := gp.(*Player)
		if player.GetRoom() != nil {
			player.GetRoom().Leave(player)
		}
		player.SetGaming(false)
	} else {
		log.Error("not found player %s", cmd.pid)
	}
}

func doAddBotCommand(c interface{}) {
	cmd := c.(*AddBotCommand)
	jr := &rpc.AiJoinArs{
		Server:    "127.0.0.1:3563",
		GameName:  cmd.game,
		GamePlace: cmd.game, //TODO
	}
	rpc.AddAI(conf.Server.AIRPC, jr)
}
func doAddLogCommand(c interface{}) {
	cmd := c.(*AddLogCommand)
	log.Debug("=== >Log cmd %+v", cmd)
	save := global.SingleSave{
		Type: 1,
		Data: cmd.glog,
		Err:  make(chan error, 1),
	}
	global.OnSingleSave <- save
	// 游戏日志保存成功后，用户关联日志
	if err := <-save.Err; err == nil {
		log.Debug("Save game glog %s ok.", cmd.glog.LogUuid)
		save.Data = cmd.ulog
		save.Type = 2
		save.Length = len(cmd.ulog)
		// 保存关联数据
		global.OnSingleSave <- save
		if err := <-save.Err; err != nil {
			// save error
			log.Release("Save game & user glog failed %s", err)
		} else {
			log.Debug("Save game<->user glog %s ok.", cmd.glog.LogUuid)
		}
	} else {
		log.Release("Add Game Log Failed, error %s", err)
	}
}
