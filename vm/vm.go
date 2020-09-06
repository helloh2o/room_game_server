package vm

import (
	"io/ioutil"
	"reflect"
	"server/leaf/log"
	loader "server/lua"
	jit "server/luajit"

	"github.com/google/uuid"
)

type VM struct {
	Uuid     string
	GameName string
	s        *jit.State
	update   chan string
	CallChan chan CallData
	bucket   *loader.LuaBucket
}

// 初始化虚拟机,游戏名字，游戏路径
func NewVM(game, rootluafile string) *VM {
	vm := new(VM)
	vm.Uuid = uuid.New().String()
	vm.s = jit.Newstate()
	vm.s.Openlibs()
	// 找到game path
	data, err := ioutil.ReadFile(rootluafile)
	if err != nil {
		log.Debug("Creat VM failed, can't read root lua file %s ", rootluafile)
		return nil
	}
	// 加载root.lua
	err = vm.s.Loadstring(string(data))
	if err != nil {
		log.Debug("Creat VM failed, load root.lua err %s ", err)
		return nil
	}
	err = vm.s.Pcall(0, 0, 0)
	if err != nil {
		log.Debug("Creat VM failed, Pcall root.lua err %s %s ", err, vm.s.Tostring(-1))
		return nil
	} else {
		log.Debug("Pcall root file ok %s", rootluafile)
	}
	// 获取游戏路径
	vm.s.Getglobal("get_game_path")
	err = vm.s.Pcall(0, 1, 0)
	if err != nil {
		log.Debug("Creat VM failed, get_game_path err %s %s", err, vm.s.Tostring(-1))
		return nil
	}
	// 游戏路径
	path := vm.s.Tostring(-1)
	vm.GameName = game
	vm.update = make(chan string)
	vm.CallChan = make(chan CallData)
	vm.bucket = new(loader.LuaBucket)
	vm.bucket.SetDir(path)
	scripts, err := vm.bucket.Load(vm.update)
	if err != nil {
		log.Debug("Load game scripts error %v ", err)
		return nil
	}
	// 加载代码
	for file, code := range scripts {
		if file == rootluafile {
			continue
		}
		vm.s.Loadstring(code)
		err = vm.s.Pcall(0, 0, 0)
		log.Debug("Pcall file %s ", file)
		if err != nil {
			log.Error("Something err, Stack size %d info %s,  ", vm.s.Gettop(), vm.s.Tostring(-1))
			return nil
		}
	}
	// 热更新
	vm.bucket.Watch()
	vm.s.Settop(0)
	go vm.Run()
	return vm
}
func (vm *VM) Run() {
	defer func() {
		if r := recover(); r != nil {
			log.Debug(" ========== VM Crashed ========== ")
		}
		vm.s.Close()
		vm.bucket.Done()
	}()
	log.Debug("Running new VM for game %s", vm.GameName)
	for {
		select {
		// 调用方法
		case calldat := <-vm.CallChan:
			// get function by name
			vm.s.Getglobal(calldat.Function)
			numArgs := vm.pushArgs(calldat.Args)
			log.Debug("========== begin to pcall %s ===========", calldat.Function)
			err := vm.s.Pcall(numArgs, jit.Multret, 0)
			log.Debug("========== end pcall %s ================", calldat.Function)
			result := CallResult{}
			if err != nil {
				result.Reason = vm.s.Tostring(-1)
				log.Release("VM call error %v, stack ==>%s", err, result.Reason)
				result.Ok = false
			} else {
				var ret []interface{}
				// 遍历所有结果
				for i := 1; i < vm.s.Gettop()+1; i++ {
					var value interface{}
					switch {
					case vm.s.Istable(i):
						value = vm.s.ToTable(i)
					case vm.s.Isboolean(i):
						value = vm.s.Toboolean(i)
					case vm.s.Isstring(i):
						value = vm.s.Tostring(i)
					case vm.s.Isnumber(i):
						v1 := vm.s.Tointeger64(i)
						v2 := vm.s.Tonumber(i)
						if float64(v1) == v2 {
							value = v1
						} else {
							value = v2
						}
					default:
						value = nil
					}
					ret = append(ret, value)
				}
				log.Debug("All call result %v", ret)
				enough := calldat.Nresult - len(ret)
				// 返回的结果不够
				if enough > 0 {
					for i := 0; i < enough; i++ {
						// 不足空值
						ret = append(ret, new(interface{}))
					}
				}
				result.Ok = true
				result.Data = ret
				// 有返回值
				if len(ret) != 0 {
					for i, v := range ret {
						log.Debug("VM callback data index %d = %v", i, v)
					}
				}
			}
			// clean the stack
			vm.s.Settop(0)
			// 传递结果
			calldat.Result <- result
		// 热更新
		case code := <-vm.update:
			vm.s.Loadstring(code)
			err := vm.s.Pcall(0, 0, 0)
			if err != nil {
				log.Error("Something err, Stack size %d info %s,  ", vm.s.Gettop(), vm.s.Tostring(-1))
			} else {
				log.Release("VM for game %s, hotupdate succeed.", vm.GameName)
			}
		}
	}
}

func (vm *VM) pushArgs(args []interface{}) (n int) {
	for _, v := range args {
		switch reflect.TypeOf(v).Kind() {
		case reflect.Int:
			v := v.(int)
			vm.s.Pushinteger(v)
		case reflect.Int32:
			v := v.(int32)
			vm.s.Pushinteger(int(v))
		case reflect.Int64:
			v := v.(int64)
			vm.s.Pushinteger(int(v))
		case reflect.Float64:
			v := v.(float64)
			vm.s.Pushnumber(v)
		case reflect.String:
			v := v.(string)
			vm.s.Pushstring(v)
		case reflect.Bool:
			v := v.(bool)
			vm.s.Pushboolean(v)
		default:
			log.Release("push unknown kind arg %s", reflect.TypeOf(v).Kind())
			vm.s.Pushnil()
		}
	}
	return len(args)
}

func (vm *VM) HotUpdate(code string) {
	vm.update <- code
}
