package db

import (
	"database/sql"
	"errors"
	"github.com/astaxie/beego/orm"
	"server/bean"
	"server/props"
)

func FindById(id string) (*bean.Player, error) {
	var p bean.Player
	o := orm.NewOrm()
	err := o.QueryTable("player").Filter("id", id).One(&p)
	if err == nil {
		return &p, nil
	}
	return nil, err
}

func QueryProps(player string) (propList []*props.Prop, err error) {
	o := orm.NewOrm()
	_, err = o.QueryTable("prop").Filter("player", player).Filter("size__gt", 0).All(&propList)
	if err == nil {
		return propList, nil
	}
	return nil, err
}
func FindByAuth(name, passwd string) (*bean.Player, error) {
	var p bean.Player
	var err error
	o := orm.NewOrm()
	qs := o.QueryTable("player").Filter("name", name).Filter("password", passwd)
	if qs.Exist() {
		err := qs.One(&p)
		if err != nil {
			return nil, err
		} else {
			return &p, nil
		}
	} else {
		err = errors.New("用户名或密码错误")
	}
	return nil, err
}
func FindByName(name string) (*bean.Player, error) {
	var p bean.Player
	o := orm.NewOrm()
	err := o.QueryTable("player").Filter("name", name).One(&p)
	if err == nil {
		return &p, nil
	}
	return nil, err
}
func Save(p interface{}) (err error) {
	o := orm.NewOrm()
	_, err = o.Insert(p)
	return
}

func InsertMulti(bulk int, data interface{}) (err error) {
	//log.Debug("InsertMulti data %+v", data)
	if data != nil {
		o := orm.NewOrm()
		_, err = o.InsertMulti(bulk, data)
	} else {
		err = errors.New("Unknow Nil data InsertMulti")
	}
	return
}

func Exist(username string) bool {
	o := orm.NewOrm()
	return o.QueryTable("player").Filter("name", username).Exist()
}

// sql 语句接口
func RawSQL(sql string, args ...interface{}) (ret sql.Result, err error) {
	o := orm.NewOrm()
	raw := o.Raw(sql, args...)
	return raw.Exec()
}

func Update(p interface{}, cols ...string) (err error) {
	o := orm.NewOrm()
	err = o.Begin()
	if err != nil {
		return err
	}
	_, err = o.Update(p, cols...)
	if err != nil {
		err = o.Rollback()
		if err != nil {
			return err
		}
	}
	err = o.Commit()
	return
}
