package login

import (
	"github.com/google/uuid"
	"server/bean"
	"server/db"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/props"
	"server/protobuf"
	"time"
)

func Login(args []interface{}) {
	m := args[0].(*protobuf.CsLogin)
	agent := args[1].(gate.Agent)
	var ret protobuf.ScError
	if m.Username != "" && m.Password != "" {
		// if in cache
		var p *bean.Player
		gp, ok := global.Players.Load(m.Username)
		if ok {
			p = gp.(*bean.Player)
		} else {
			var err error
			p, err = db.FindByAuth(m.Username, m.Password)
			if err != nil {
				ret = protobuf.ScError{Code: -1, Reason: err.Error()}
				log.Release("登录错误，%v", err)
			} else {
				// 道具
				list, err := db.QueryProps(p.Uuid)
				if err != nil {
					log.Error("db.QueryProps %s", err)
				} else {
					p.Props = list
				}
				global.Players.Store(p.Name, p)
			}
		}
		if p != nil {
			// update token
			p.Token = uuid.New().String()
			// 成功
			ok := protobuf.ScLoginSuccess{}
			ok.Player = p.Uuid
			ok.Id = int32(p.Id)
			ok.Name = p.Name
			ok.Coin = p.Coin
			ok.Exp = p.Exp
			ok.Email = p.Email
			ok.Gold = p.Gold
			ok.Head = p.Head
			ok.NickName = p.NickName
			ok.Phone = p.Phone
			ok.RoomCard = p.RoomCard
			ok.Token = p.Token
			ok.Time = time.Now().Unix()
			ok.UnionId = p.Union
			agent.WriteMsg(&ok)
			agent.SetUserData(p)
			// 道具消息
			if len(p.Props) > 0 {
				list := protobuf.ScPropList{}
				for _, per := range p.Props {
					pm := &protobuf.Prop{}
					pm.Pid = int32(per.PID)
					pm.LimitTime = per.LimitTime
					if per.Size > 0 {
						pm.Size = int32(per.Size)
						list.Pack = append(list.Pack, pm)
					}
				}
				agent.WriteMsg(&list)
			}
			// 服务器分配
			serversMsg := protobuf.ScServers{
				GameServer: "",
				ApiServer:  "http://120.26.45.235:6100",
			}
			agent.WriteMsg(&serversMsg)
			// 活动
			// 公告
			return
		}
	} else {
		ret = protobuf.ScError{Code: -1, Reason: "用户名或密码不能为空"}
	}
	agent.WriteMsg(&ret)
}

func Register(args []interface{}) {
	m := args[0].(*protobuf.CsRegister)
	agent := args[1].(gate.Agent)
	var ret protobuf.ScError
	if m.Username != "" {
		has := db.Exist(m.Username)
		if has {
			ret = protobuf.ScError{Code: -1, Reason: "用户名已经存在"}
		} else {
			// create
			p := &bean.Player{}
			p.Uuid = uuid.New().String()
			p.Name = m.Username
			p.Password = m.Password
			p.Channel = m.Channel
			p.Device = m.Device
			p.Ver = m.Ver
			p.Phone = m.Cellphone
			p.Props = make([]*props.Prop, 0)
			// save
			err := db.Save(p)
			if err != nil {
				log.Debug("save new player err %v", err)
				ret = protobuf.ScError{Code: -1, Reason: "创建用户遇到问题，请稍后再试"}
			} else {
				agent.WriteMsg(&protobuf.ScRegisterSuccess{})
				// prop
				card := props.NewProp(props.ID_Record, p.Uuid, 1, 7)
				err := db.Save(card)
				if err != nil {
					log.Error("creat prop error %s", err)
				} else {
					p.Props = append(p.Props, card)
				}
				supper := props.NewProp(props.ID_Supper, p.Uuid, 10, 7)
				err = db.Save(supper)
				if err != nil {
					log.Error("creat prop error %s", err)
				} else {
					p.Props = append(p.Props, supper)
				}
				// cache
				global.Players.Store(p.Name, p)
			}
		}
	}
	agent.WriteMsg(&ret)
}

func UpdateLocation(args []interface{}) {
	m := args[0].(*protobuf.CsLocation)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		p.Location = m.Location
		global.Players.Store(p.Name, p)
		global.Players.Store(p.Uuid, p)
		agent.WriteMsg(&protobuf.ScLocation{Location: p.Location})
	} else {
		agent.WriteMsg(&protobuf.ScError{Code: bean.NEED_RE_LOGIN, Reason: ""})
	}
}
