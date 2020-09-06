package bean

type GameLog struct {
	Id        int64  `json:"id"`
	GroupId   string `json:"group_id"`
	LogUuid   string `json:"uuid" orm:"unique;index"`
	GameType  string `json:"game_type" orm:"index"`
	RoomPwd   string `json:"room_pwd"`
	LogData   string `json:"log_data" orm:"type(jsonb)"`
	BeginTime int64  `json:"begin_time"`
	RoomUuid  string `json:"room_uuid"`
}

type UserLog struct {
	Id       int64  `json:"id"`
	PlayerId int64  `json:"player_id" orm:"index"`
	LogUuid  string `json:"log_uuid" orm:"index"`
	AddTime  int64  `json:"add_time"`
}

// 多字段唯一
func (lg *UserLog) TableUnique() [][]string {
	return [][]string{
		[]string{"PlayerId", "LogUuid"},
	}
}
