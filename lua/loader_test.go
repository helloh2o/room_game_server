package loader

/*
import (
	"fmt"
	lua "github.com/yuin/gopher-lua"
	"log"
	"strconv"
	"sync"
	"testing"
	"time"
)

func TestLuaBucket_ReLoad(t *testing.T) {
	Bucket.SetDir("D:/Dev/go/src/server/lua/game")
	Bucket.Load()
	go Bucket.Watch()
	var wg sync.WaitGroup
	wg.Add(100)
	for i := 0; i < 100; i++ {
		time.Sleep(time.Second)
		ch := make(chan lua.LValue)
		quit := make(chan lua.LValue)
		out := make(chan lua.LValue)
		// run lua
		go func(ch, quit chan lua.LValue) {
			L := lua.NewState()
			defer L.Close()
			scripts := Bucket.scripts
			L.SetGlobal("ch", lua.LChannel(ch))
			L.SetGlobal("quit", lua.LChannel(quit))
			L.SetGlobal("out", lua.LChannel(out))
			for _, luafile := range scripts {
				if err := L.DoString(luafile); err != nil {
					log.Printf("ERROR:: %s\n", err)
				}
				//fmt.Printf("Script:: \n%s\n", luafile)
			}
		}(ch, quit)
		// like room
		go func(ch, quit, out chan lua.LValue, id int) {
			done := make(chan struct{})
			go func() {
				for {
					select {
					case data := <-out:
						fmt.Println("收到消息")
						luastring, ok := data.(lua.LString)
						if ok {
							fmt.Printf("out message -> %s \n", string(luastring))
						}
					case <-done:
						fmt.Println("done")
						return
					}
				}
			}()
			for i := 1; i < 10; i++ {
				//time.Sleep(time.Second)
				ch <- lua.LString(strconv.Itoa(id))
			}
			quit <- lua.LTrue
			done <- struct{}{}
			wg.Done()
		}(ch, quit, out, i)
	}
	wg.Wait()
}
*/
