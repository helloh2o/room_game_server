package db

import (
	"github.com/astaxie/beego/orm"
	"github.com/google/uuid"
	"log"
	"server/bean"
	"server/global"
	"server/props"
	"testing"
	"time"
)

func TestInsert(t *testing.T) {
	PGRun()
	o := orm.NewOrm()
	p := bean.Player{Uuid: uuid.New().String(), Name: "Test1"}
	n, err := o.Insert(&p)
	if err != nil {
		log.Printf("insert err %v", err)
	} else {
		log.Printf("save item %d", n)
	}
}

func TestQueryOne(t *testing.T) {
	PGRun()
	o := orm.NewOrm()
	var user bean.Player
	err := o.QueryTable("player").One(&user)
	if err != nil {
		log.Printf("query err %v", err)
	} else {
		log.Printf("query item %+v", user)
	}
}

func TestFindByAuth(t *testing.T) {
	PGRun()
	p, err := FindByAuth("Test2", "")
	if err != nil {
		log.Fatal(err)
	} else {
		log.Printf("player %+v", p)
	}
}

func TestFindLog(t *testing.T) {
	PGRun()
	page := 1
	var ulog []*bean.UserLog
	o := orm.NewOrm()
	_, err := o.QueryTable("user_log").Offset(page - 1*20).Limit(20).All(&ulog)
	if err != nil {
		log.Printf("Query user log error %s", err)
	} else {
		if len(ulog) == 0 {

		} else {
			loguuids := make([]interface{}, 0)
			for _, per := range ulog {
				loguuids = append(loguuids, per.LogUuid)
			}
			var gameLogs []*bean.GameLog
			_, err = o.QueryTable("game_log").Filter("log_uuid__in", loguuids...).All(&gameLogs)
			if err != nil {
				log.Printf("Query game log error %s", err)
			} else {
				log.Printf("%+v", gameLogs)
			}
			// find all game log
			_, err = o.QueryTable("game_log").All(&gameLogs)
			log.Printf("%+v", gameLogs)
		}
	}
}
func TestInsertSave(t *testing.T) {
	PGRun()
	gss := global.SingleSave{
		Data: &bean.GameLog{
			GroupId:   uuid.New().String(),
			LogUuid:   uuid.New().String(),
			GameType:  "111",
			RoomPwd:   "111",
			LogData:   "{}",
			BeginTime: time.Now().Unix(),
			RoomUuid:  "",
		},
		Type: 1,
		Err:  make(chan error, 1),
	}
	global.OnSingleSave <- gss
	err := <-gss.Err
	log.Print(err)
}

func TestDeleletMailUnion(t *testing.T) {
	PGRun()
	o := orm.NewOrm()
	n, err := o.QueryTable("union").Filter("id__gt", 0).Delete()
	if err == nil {
		log.Printf("delete %d union", n)
	}
	n, err = o.QueryTable("mail").Filter("id__gt", 0).Delete()
	if err == nil {
		log.Printf("delete %d mail", n)
	}
	n, err = o.QueryTable("player").Filter("id__gt", 0).Update(orm.Params{
		"union": 0,
	})
	if err == nil {
		log.Printf("update %d players", n)
	}
}

func TestInsertMulti(t *testing.T) {
	PGRun()
	ulogs := make([]*bean.UserLog, 0)
	for i := 0; i < 3; i++ {
		l := bean.UserLog{
			PlayerId: int64(i),
			LogUuid:  uuid.New().String(),
			AddTime:  time.Now().Unix(),
		}
		ulogs = append(ulogs, &l)
	}
	InsertMulti(len(ulogs), ulogs)
}

func TestRawSQL(t *testing.T) {
	PGRun()
	//sql := "select count(1) from player;"
	sql := "INSERT INTO player (name,uuid) VALUES ('aa','11dfasdfdsaf');"
	ret, err := RawSQL(sql)
	if err != nil {
		log.Fatal(err)
	} else {
		n, err := ret.RowsAffected()
		log.Printf("RowsAffected %v error %v", n, err)
	}
}

func TestSave(t *testing.T) {
	PGRun()
	// prop
	card := props.NewProp(props.ID_Record, "DSFASDF", 1, 7)
	err := Save(card)
	if err != nil {
		log.Printf("creat prop error %s", err)
	}
	supper := props.NewProp(props.ID_Supper, "DSFASDF", 10, 7)
	err = Save(supper)
	if err != nil {
		log.Printf("creat prop error %s", err)
	}
}

func TestMail(t *testing.T) {
	PGRun()
	o := orm.NewOrm()
	var mails []bean.Mail
	//_, err := o.QueryTable("mail").All(&mails)
	_, err := o.QueryTable("mail").Filter("receiver", "c8d0ec08-b75e-4e77-b1e8-58b376049efc").Filter("read", false).Limit(50).All(&mails)
	if err != nil {
		panic(err)
	}
	log.Printf("%+v", mails)
}
