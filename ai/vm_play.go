package ai

import (
	"flag"
	"log"
	"server/vm"
)

var (
	_vm  *vm.VM
	root = flag.String("root", "D:/gohub/src/server/ai/lua/root.lua", "lua root file.")
)

// 具体的AI打牌算法，交给LUA托管
func InitPlayRule() {
	_vm = vm.NewVM("ddz", *root)
	if _vm != nil {
		log.Printf("create game %s vm %s", "ddz", _vm.Uuid)
	} else {
		log.Printf("created vm failed for game %s", "ddz")
	}
}
