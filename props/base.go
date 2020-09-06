package props

const (
	Unknown = iota
	ID_Record
	ID_Supper
)

type Prop struct {
	Id        int64  `json:"id"`                     // DB PK
	PID       int    `json:"pid" orm:"unique;index"` // 道具ID
	Player    string `json:"player"`                 // 用户UUID
	Size      int    `json:"size"`                   // 数量
	LimitTime int64  `json:"limit_time"`             // 期限
	Price     int32  `json:"price"`                  // 售价
}
