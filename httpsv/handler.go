package httpsv

import (
	"github.com/astaxie/beego/orm"
	"github.com/kataras/iris/context"
	"server/bean"
	"server/leaf/log"
)

func init() {
	app.Get("/", func(ctx context.Context) {
		ctx.StatusCode(403)
	})
	app.Get("/game/record/{id}/{page}", func(ctx context.Context) {
		id := ctx.Params().Get("id")
		page, err := ctx.Params().GetInt("page")
		if err != nil {
			// default page 1
			page = 1
		}
		var ulog []*bean.UserLog
		o := orm.NewOrm()
		_, err = o.QueryTable("user_log").Filter("player_id", id).Offset(page - 1*20).Limit(20).All(&ulog)
		ret := &Resp{}
		if err != nil {
			log.Error("Query user log error %s", err)
			ret.Ret = -1
			ret.Error = err.Error()
		} else {
			if len(ulog) == 0 {
				// 没有日志
				ret.DATA = make([]*bean.GameLog, 0)
			} else {
				loguuids := make([]interface{}, 0)
				for _, per := range ulog {
					loguuids = append(loguuids, per.LogUuid)
				}
				var gameLogs []*bean.GameLog
				_, err = o.QueryTable("game_log").Filter("log_uuid__in", loguuids...).All(&gameLogs)
				if err != nil {
					log.Error("Query game log error %s", err)
					ret.Error = err.Error()
					ret.Ret = -1
				} else {
					ret.DATA = gameLogs
				}
			}
		}
		ctx.JSON(ret)
	})
}
