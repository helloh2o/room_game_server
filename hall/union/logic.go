package union

import (
	"encoding/json"
	"fmt"
	"github.com/astaxie/beego/orm"
	"server/bean"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/protobuf"
)

func Query(args []interface{}) {
	m := args[0].(*protobuf.CsQueryUnion)
	agent := args[1].(gate.Agent)
	_, ok := agent.UserData().(*bean.Player)
	result := protobuf.ScQueryUnion{
		Unions: nil,
	}
	if ok { // m.Name != "" &&
		var us []bean.Union
		o := orm.NewOrm()
		_, err := o.QueryTable("union").Filter("name__icontains", m.Name).Limit(20).All(&us)
		if err != nil {
			log.Error("query union error %s", err)
		} else {
			var list []*protobuf.ScUnionInfo
			for _, u := range us {
				pus := protobuf.ScUnionInfo{
					Id:            u.Id,
					Name:          u.Name,
					Level:         int32(u.Level),
					Notice:        u.Notice,
					Des:           u.Des,
					Score:         u.Score,
					MasterId:      u.MasterId,
					Creator:       u.Creater,
					CreateTime:    u.CreateTime,
					MaxMember:     int32(u.MaxMember),
					Status:        int32(u.Status),
					CurrentMember: u.Members,
					MasterUuid:    u.MasterUuid,
				}
				list = append(list, &pus)
			}
			result.Unions = list
		}
	}
	agent.WriteMsg(&result)
}

func Join(args []interface{}) {
	m := args[0].(*protobuf.CsJoinUnion)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	ret := protobuf.ScJoinUnion{
		Ok:     false,
		Reason: "",
		Info:   nil,
	}
	if !ok {
		ret.Reason = "无效连接，需要重新登录"
	} else if p.Union > 0 {
		ret.Reason = fmt.Sprint("Player already in union ", p.Union)
	} else {
		var union bean.Union
		// find union
		o := orm.NewOrm()
		err := o.QueryTable("union").Filter("id", m.UnionId).One(&union)
		if err != nil {
			ret.Reason = "query union error"
		} else {
			switch union.Status {
			case 0:
				ret.Ok = true
				p.Union = int64(m.UnionId)
				union.Members++
				ret.Info = &protobuf.ScUnionInfo{
					Id:         union.Id,
					Name:       union.Name,
					Level:      int32(union.Level),
					Notice:     union.Notice,
					Des:        union.Des,
					Score:      union.Score,
					MasterId:   union.MasterId,
					Creator:    union.Creater,
					CreateTime: union.CreateTime,
					MaxMember:  int32(union.MaxMember),
					Status:     int32(union.Status),
					MasterUuid: union.MasterUuid,
				}
				o.Update(&union, "members")
				// send email to p
				mail := bean.Mail{
					Type:     bean.MAIL_MESSAGE,
					Sender:   "sys",
					Receiver: p.Uuid,
					Title:    "加入公会成功",
					Content:  fmt.Sprint("恭喜您，加入公会 ", union.Name),
					Attach:   "",
				}
				_, err = o.Insert(&mail)
				if err != nil {
					log.Error("insert mail err %v", err)
				} else {
					// 发送成功
					pkmails := protobuf.ScMails{}
					var pm protobuf.Mail
					err := json.Unmarshal(mail.ToJson(), &pm)
					if err != nil {
						log.Error("to protobuf.Mail err %v", err)
					} else {
						pkmails.Mails = append(pkmails.Mails, &pm)
						agent.WriteMsg(&pkmails)
					}
				}
				global.Players.Store(p.Uuid, p)
				global.Players.Store(p.Name, p)
				agent.SetUserData(p)
			case 1:
				// send email to master
				mail := bean.Mail{
					Type:     bean.MAIL_JOIN_UNION,
					Sender:   p.Uuid,
					Receiver: union.MasterUuid,
					Title:    "申请加入公会",
					Content:  "",
					Attach:   fmt.Sprint(m.UnionId),
				}
				gs := global.SingleSave{
					Data:   &mail,
					Err:    make(chan error, 1),
					Type:   1,
					Length: 0,
				}
				global.OnSingleSave <- gs
				err := <-gs.Err
				if err != nil {
					ret.Reason = "mail send error"
				} else {
					ret.Ok = true
				}
			case 2:
				ret.Reason = "error request"
			}
		}
	}
	agent.WriteMsg(&ret)
}

func Exit(args []interface{}) {
	m := args[0].(*protobuf.CsExitUnion)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	ret := protobuf.ScExitUnion{
		Ok:  false,
		Des: "",
	}
	if ok {
		var union bean.Union
		// find union
		o := orm.NewOrm()
		err := o.QueryTable("union").Filter("id", m.UnionId).One(&union)
		if err != nil {
			ret.Des = "query union error"
		} else {
			if p.Union > 0 && p.Id != union.MasterId {
				_, err = o.Update(p, "union")
				if err == nil {
					union.Members--
					p.Union = 0
					global.Players.Store(p.Uuid, p)
					global.Players.Store(p.Name, p)
					agent.SetUserData(p)
					ret.Ok = true
					o.Update(&union, "members")
				} else {
					ret.Des = "update player error"
				}

			} else {
				ret.Des = "player not in some union"
			}
		}
		agent.WriteMsg(&ret)
	}
}

func Settings(args []interface{}) {
	m := args[0].(*protobuf.CsUnionSettings)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		var union bean.Union
		// find union
		o := orm.NewOrm()
		err := o.QueryTable("union").Filter("id", p.Union).One(&union)
		if err == nil {
			if union.MasterId == p.Id {
				union.Des = m.Des
				union.Status = int(m.Verify)
				union.Notice = m.Notice
				o.Update(&union)
			}
		} else {
			log.Error("query union for settings err , union id %d", p.Uuid)
		}
	} else {
		agent.WriteMsg(&protobuf.ScError{
			Code:   -1,
			Reason: "Need re-login",
		})
	}
}

func Transfer(args []interface{}) {
	m := args[0].(*protobuf.CsTransferMaster)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		if p.Union == 0 {
			agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_UNION, Reason: ""})
		} else {
			var u bean.Union
			o := orm.NewOrm()
			err := o.QueryTable("union").Filter("id", p.Union).One(&u)
			if err != nil {
				agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_UNION, Reason: ""})
				return
			}
			if u.MasterId == p.Id {
				//find target
				var tp bean.Player
				cp, ok := global.Players.Load(p.Uuid)
				if ok {
					tp = *cp.(*bean.Player)
				} else {
					err := o.QueryTable("player").Filter("uuid", m.Uuid).One(&tp)
					if err != nil {
						agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_PLAYER, Reason: ""})
						return
					} else {
						if tp.Union == u.Id {
							u.MasterId = tp.Id
							u.MasterUuid = tp.Uuid
							_, err = o.Update(&u, "master_id", "master_uuid")
							if err == nil {
								agent.WriteMsg(&protobuf.ScTransferMaster{Uuid: m.Uuid})
								// email
								mail := bean.Mail{
									Type:     bean.MAIL_MESSAGE,
									Sender:   "sys",
									Receiver: m.Uuid,
									Title:    "公会消息",
									Content:  fmt.Sprint("公会转让，恭喜您成为公会： ", u.Name, " 管理员"),
									Attach:   "",
								}
								_, err = o.Insert(&mail)
								return
							}
						}
						log.Error("Transfer err %v player union %d, Union", err, p.Union, u.Id)
						agent.WriteMsg(&protobuf.ScError{Code: bean.TRANSTER_UNION_FAILED, Reason: "Unknown error"})
					}
				}
			} else {
				agent.WriteMsg(&protobuf.ScError{Code: bean.MASTER_ID_ERR, Reason: ""})
			}
		}
	}
}

func TickMember(args []interface{}) {
	m := args[0].(*protobuf.CsTickMember)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		o := orm.NewOrm()
		if o.QueryTable("union").Filter("id", p.Union).Filter("master_id", p.Id).Exist() {
			var tp *bean.Player
			cp, ok := global.Players.Load(m.Uuid)
			if ok {
				tp = cp.(*bean.Player)
			} else {
				var temp bean.Player
				err := o.QueryTable("player").Filter("uuid", m.Uuid).One(&temp)
				if err != nil {
					agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_PLAYER, Reason: ""})
					return
				}
				tp = &temp
				tp.Union = 0
				agent.WriteMsg(&protobuf.ScTickMember{Uuid: m.Uuid})
				o.Update(&tp, "union")
				global.Players.Store(tp.Name, &tp)
				global.Players.Store(tp.Uuid, &tp)
				// email
				mail := bean.Mail{
					Type:     bean.MAIL_MESSAGE,
					Sender:   "sys",
					Receiver: m.Uuid,
					Title:    "公会消息",
					Content:  fmt.Sprint("抱歉，您被踢出公会。"),
					Attach:   "",
				}
				_, err = o.Insert(&mail)
			}
		} else {
			agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_UNION, Reason: ""})
		}
	}
}

// rank by score
func RankRoll(args []interface{}) {
	agent := args[1].(gate.Agent)
	_, ok := agent.UserData().(*bean.Player)
	if ok {
		var us []bean.Union
		o := orm.NewOrm()
		n, err := o.QueryTable("union").OrderBy("score").Limit(100).All(&us)
		if err != nil {
			log.Error("query rank size %d error %v", n, err)
			agent.WriteMsg(&protobuf.ScError{Code: bean.NOT_FOUND_UNION, Reason: ""})
		} else {
			var list []*protobuf.ScUnionInfo
			for _, u := range us {
				pus := protobuf.ScUnionInfo{
					Id:            u.Id,
					Name:          u.Name,
					Level:         int32(u.Level),
					Notice:        u.Notice,
					Des:           u.Des,
					Score:         u.Score,
					MasterId:      u.MasterId,
					Creator:       u.Creater,
					CreateTime:    u.CreateTime,
					MaxMember:     int32(u.MaxMember),
					Status:        int32(u.Status),
					CurrentMember: u.Members,
					MasterUuid:    u.MasterUuid,
				}
				list = append(list, &pus)
			}
			data := protobuf.ScUnionRank{
				Unions: list,
			}
			agent.WriteMsg(&data)
		}
	}
}
