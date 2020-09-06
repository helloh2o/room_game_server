package union

import (
	"github.com/astaxie/beego/orm"
	"server/bean"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/protobuf"
)

func GetUnionDetail(args []interface{}) {
	m := args[0].(*protobuf.CsUnionInfo)
	agent := args[1].(gate.Agent)
	p, ok := agent.UserData().(*bean.Player)
	if ok {
		qUnionId := m.UnionId
		if qUnionId == -1 {
			cp, ok := global.Players.Load(p.Uuid)
			if ok {
				cp := cp.(*bean.Player)
				qUnionId = cp.Union
			}
		}
		o := orm.NewOrm()
		var u bean.Union
		err := o.QueryTable("union").Filter("id", qUnionId).One(&u)
		if err != nil {
			log.Error("Get Union detail error %v", err)
			errInfo := protobuf.ScError{
				Code:   bean.NOT_FOUND_UNION,
				Reason: "",
			}
			agent.WriteMsg(&errInfo)
			return
		} else {
			var members []*bean.Player
			_, err = o.QueryTable("player").Filter("union", qUnionId).All(&members)
			if err != nil {
				log.Error("Get Union detail error %v", err)
				errInfo := protobuf.ScError{
					Code:   bean.NOT_FOUND_UNION,
					Reason: "",
				}
				agent.WriteMsg(&errInfo)
				return
			} else {
				pu := protobuf.ScUnionInfo{
					Id:         u.Id,
					Name:       u.Name,
					Level:      int32(u.Level),
					Notice:     u.Notice,
					Des:        u.Des,
					Score:      u.Score,
					MasterId:   u.MasterId,
					Creator:    u.Creater,
					CreateTime: u.CreateTime,
					MaxMember:  int32(u.MaxMember),
					Status:     int32(u.Status),
				}
				pu.Members = make([]*protobuf.ScUnionMember, 0)
				for _, p := range members {
					scum := protobuf.ScUnionMember{
						PlayerUuid: p.Uuid,
						Name:       p.Name,
						Level:      p.Level,
						UnionVal:   p.UnionVal,
						Head:       p.Head,
					}
					pu.Members = append(pu.Members, &scum)
				}
				agent.WriteMsg(&pu)
			}
		}
	}
}
