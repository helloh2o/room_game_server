package conf

import (
	"encoding/json"
	"io/ioutil"
	"server/leaf/log"
)

var Server struct {
	LogLevel    string
	LogPath     string
	WSAddr      string
	CertFile    string
	KeyFile     string
	TCPAddr     string
	HTTPAddr    string
	MaxConnNum  int
	ConsolePort int
	ProfilePath string
	DBSource    string
	DBMaxConn   int
	DBIdleConn  int
	//lua script
	Games []Game
	//包混淆加密
	EncryptStr string
	//AI RPC 服务地址
	AIRPC string
}

type Game struct {
	Name   string `json:"name"`
	Root   string `json:"root"`
	VmSize int    `json:"vm_size"` // 虚拟机个数
	Room   int    `json:"room"`    // 初始化房间个数
	Des    string `json:"des"`
}

func init() {
	data, err := ioutil.ReadFile("conf/server.json")
	if err != nil {
		log.Fatal("%v", err)
	}
	err = json.Unmarshal(data, &Server)
	if err != nil {
		log.Fatal("%v", err)
	}
}
