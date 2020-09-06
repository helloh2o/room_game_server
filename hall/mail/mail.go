package mail

import (
	"encoding/json"
	"fmt"
	"github.com/astaxie/beego/orm"
	"server/bean"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/protobuf"
	"strconv"
)

func ReadMail(args []interface{}) {
	m := args[0].(*protobuf.CsReadMail)
	agent := args[1].(gate.Agent)
	_, ok := agent.UserData().(*bean.Player)
	if ok {
		o := orm.NewOrm()
		var mail bean.Mail
		var sender bean.Player
		err := o.QueryTable("mail").Filter("id", m.MailId).One(&mail)
		if err != nil {
			log.Error("update mail err %v", err)
		} else {
			gp, ok := global.Players.Load(mail.Sender)
			if ok {
				// update cache
				ch, _ := gp.(*bean.Player)
				sender = *ch
			} else {
				// find in db
				err = o.QueryTable("player").Filter("uuid", mail.Sender).One(&sender)
			}
			if err == nil {
				switch mail.Type {
				case bean.MAIL_JOIN_UNION:
					unionId, err := strconv.Atoi(mail.Attach)
					if sender.Union > 0 {
						log.Error("Player already in union %d", sender.Union)
					} else if err == nil {
						sender.Union = int64(unionId)
						_, err := o.Update(&sender)
						if err == nil {
							global.Players.Store(sender.Uuid, &sender)
							global.Players.Store(sender.Name, &sender)
							var un bean.Union
							err = o.QueryTable("union").Filter("id", unionId).One(&un)
							var mail bean.Mail
							if err == nil {
								if m.Confirm {
									// send email to master
									mail = bean.Mail{
										Type:     bean.MAIL_MESSAGE,
										Sender:   "sys",
										Receiver: sender.Uuid,
										Title:    "加入公会成功",
										Content:  fmt.Sprint("恭喜您，加入公会 ", un.Name),
										Attach:   "",
									}
								} else {
									mail = bean.Mail{
										Type:     bean.MAIL_MESSAGE,
										Sender:   "sys",
										Receiver: sender.Uuid,
										Title:    "加入公会失败",
										Content:  fmt.Sprint("公会 ", un.Name, " 拒绝了您的申请。"),
										Attach:   "",
									}
								}
								_, err = o.Insert(&mail)
								if err != nil {
									log.Error("insert mail err %v", err)
								} else {
									// 发送成功
									if sender.Agent() != nil { // 在线
										pkmails := protobuf.ScMails{}
										var pm protobuf.Mail
										err := json.Unmarshal(mail.ToJson(), &pm)
										if err != nil {
											log.Error("to protobuf.Mail err %v", err)
										} else {
											pkmails.Mails = append(pkmails.Mails, &pm)
											sender.Agent().WriteMsg(&pkmails)
										}
									}
								}
							} else {
								log.Error("query union err %v", err)
							}
						} else {
							log.Error("update mail sender err %v", err)
						}
					} else {
						log.Error("union id err %v", unionId)
					}
				}
			}
			mail.Read = true
			o.Update(&mail)
		}
	}
}

func PullMail(args []interface{}) {
	//m := args[0].(*protobuf.CsMailReq)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		o := orm.NewOrm()
		var mails []bean.Mail
		pkmails := protobuf.ScMails{}
		_, err := o.QueryTable("mail").Filter("receiver", p.Uuid).Filter("read", false).Limit(50).All(&mails)
		if err != nil {
			log.Error("pull user mails err %v", err)
		} else {
			for _, m := range mails {
				var pm protobuf.Mail
				err := json.Unmarshal(m.ToJson(), &pm)
				if err != nil {
					log.Error("to protobuf.Mail err %v", err)
					continue
				}
				pkmails.Mails = append(pkmails.Mails, &pm)
			}
		}
		agent.WriteMsg(&pkmails)
	}
}
