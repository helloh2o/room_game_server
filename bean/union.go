package bean

import (
	"encoding/json"
	"server/leaf/log"
)

type Union struct {
	Id         int64  `json:"id"`
	Name       string `json:"name" orm:"unique;index"` // 唯一，索引
	Level      int    `json:"level"`
	Notice     string `json:"notice"` // 公告
	Des        string `json:"des"`    // 描述
	Score      int64  `json:"score"`
	MasterId   int64  `json:"master_id"`
	MasterUuid string `json:"master_uuid"`
	Creater    string `json:"creater"`
	CreateTime int64  `json:"create_time"`
	MaxMember  int    `json:"max_member"`
	Members    int32  `json:"members"`
	Status     int    `json:"status"` //0=open// 1= 验证 // 2= 拒绝
	Rank       int32  `json:"rank"`
}

// 邮件
type Mail struct {
	Id       int64  `json:"id"`
	Type     int    `json:"type"`
	Sender   string `json:"sender"`
	Receiver string `json:"receiver" orm:"index"`
	Title    string `json:"title"`
	Content  string `json:"content"`
	Attach   string `json:"attach"`
	Read     bool   `json:"read"`
}

func (m *Mail) ToJson() []byte {
	data, err := json.Marshal(m)
	if err != nil {
		log.Error("Marshal MAIL ERR, %v", err)
		return nil
	} else {
		return data
	}
}
