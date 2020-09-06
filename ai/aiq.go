package ai

import (
	"fmt"
	"github.com/astaxie/beego/orm"
	"github.com/google/uuid"
	"github.com/helloh2o/collections"
	"server/bean"
	"server/db"
	"server/global"
	"server/leaf/log"
	"server/props"
)

var (
	// 可用的AI 队列
	aiQueue = collections.NewQueue()
)

func Init(max int) {
	db.PGRun()
	o := orm.NewOrm()
	ais := make([]*bean.Player, 0)
	n, err := o.QueryTable("player").Filter("Robot", true).Limit(max + 1).Count()
	if err != nil {
		log.Fatal("%v", err)
	} else if n == 0 {
		// 初始化AI 数据
		for i := 0; i < 4; i++ {
			for j := n; j < 3000; j++ {
				// create
				p := &bean.Player{}
				p.Uuid = uuid.New().String()
				p.Gold = 10000000
				p.RoomCard = 1000000
				nx := i*3000 + int(j)
				p.Name = fmt.Sprint("编号", nx)
				p.NickName = fmt.Sprint("编号", nx)
				p.Props = make([]*props.Prop, 0)
				p.Robot = true
				p.Phone = p.Uuid
				p.Email = p.Uuid + "@.robot"
				p.Device = p.Uuid + "@device"
				ais = append(ais, p)
			}
			gsv := global.SingleSave{
				Data:   ais,
				Err:    make(chan error, 1),
				Type:   2,
				Length: len(ais),
			}
			global.OnSingleSave <- gsv
			err = <-gsv.Err
			if err != nil {
				log.Error("Save robots error %v", err)
			}
			ais = ais[:0]
		}
	}
	_, err = o.QueryTable("player").Filter("robot", true).Limit(max).All(&ais)
	if err != nil {
		log.Error("query robot error %v", err)
	} else {
		log.Release("Load AI player %d", len(ais))
	}
	// 初始化AI 数据
	for _, p := range ais {
		aiQueue.Put(p)
	}
	log.Release("AI queue size %d", max)
}

func getAi() *bean.Player {
	if aiQueue.IsEmpty() {
		return nil
	}
	v, _ := aiQueue.Get()
	p, ok := v.(*bean.Player)
	if !ok {
		return nil
	}
	return p
}

func putAi(ai interface{}) {
	aiQueue.Put(ai)
}
