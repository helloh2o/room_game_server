package union

import (
	"github.com/astaxie/beego/orm"
	"server/bean"
	"server/global"
	"server/leaf/gate"
	"server/leaf/log"
	"server/protobuf"
	"time"
)

func CreateUnion(args []interface{}) {
	m := args[0].(*protobuf.CsCreateUnion)
	agent := args[1].(gate.Agent)
	creator, ok := agent.UserData().(*bean.Player)
	ret := protobuf.ScCreateUnion{
		Ok:   false,
		Info: nil,
	}
	if ok {
		o := orm.NewOrm()
		if o.QueryTable("union").Filter("name", m.Name).Exist() {
			errInfo := protobuf.ScError{
				Code:   bean.CREATE_UNION_FAILED_NAME_EXIST,
				Reason: "",
			}
			agent.WriteMsg(&errInfo)
			return
		}
		un := new(bean.Union)
		un.Name = m.Name
		un.Creater = creator.Name
		un.MasterId = creator.Id
		un.MasterUuid = creator.Uuid
		un.CreateTime = time.Now().Unix()
		un.Level = 1
		un.MaxMember = 200
		un.Des = m.Des
		un.Members++
		gs := global.SingleSave{
			Data:   un,
			Err:    make(chan error, 1),
			Type:   1,
			Length: 0,
		}
		global.OnSingleSave <- gs
		err := <-gs.Err
		if err != nil {
			log.Error("CreateUnion Error %s", err.Error())
			errInfo := protobuf.ScError{
				Code:   bean.CREATE_UNION_FAILED,
				Reason: err.Error(),
			}
			agent.WriteMsg(&errInfo)
			return
		}
		creator.Union = un.Id
		global.Players.Store(creator.Uuid, creator)
		global.Players.Store(creator.Name, creator)
		// update creator
		gs.Data = creator
		gs.Type = 0
		global.OnSingleSave <- gs
		err = <-gs.Err
		if err != nil {
			log.Error("update creator err %v", err)
		}
		ret.Ok = true
		ret.Info = &protobuf.ScUnionInfo{
			Id:         un.Id,
			Name:       un.Name,
			Level:      1,
			Notice:     un.Notice,
			Des:        un.Des,
			Score:      un.Score,
			MasterId:   un.MasterId,
			Creator:    un.Creater,
			CreateTime: un.CreateTime,
			MaxMember:  int32(un.MaxMember),
			Status:     int32(un.Status),
			MasterUuid: un.MasterUuid,
		}
		mb := protobuf.ScUnionMember{
			Name:       creator.Name,
			Level:      creator.Level,
			UnionVal:   creator.UnionVal,
			Head:       creator.Head,
			PlayerUuid: creator.Uuid,
		}
		ret.Info.Members = []*protobuf.ScUnionMember{&mb}
	} else {
		ret.Reason = "无效连接，需要重新登录"
	}
	agent.WriteMsg(&ret)
}

func DestroyUnion(un *bean.Union) {

}
