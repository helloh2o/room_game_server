package db

import (
	"github.com/astaxie/beego/orm"
	_ "github.com/lib/pq"
	"server/bean"
	"server/conf"
	"server/props"
)

func PGRun() {
	orm.RegisterDriver("postgres", orm.DRPostgres)
	orm.RegisterDataBase("default", "postgres", conf.Server.DBSource)
	orm.RegisterModel(
		new(bean.Player),
		new(props.Prop),
		new(bean.GameLog),
		new(bean.UserLog),
		new(bean.Union),
		new(bean.Mail),
	)
	orm.RunSyncdb("default", false, true)
	orm.SetMaxIdleConns("default", conf.Server.DBMaxConn)
	orm.SetMaxOpenConns("default", conf.Server.DBIdleConn)
}
