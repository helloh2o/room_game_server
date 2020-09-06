package loader

import (
	"fmt"
	"github.com/fsnotify/fsnotify"
	"io/ioutil"
	"runtime/debug"
	"server/leaf/log"
	"strings"
	"sync"
	"time"
)

type LuaBucket struct {
	dir     string
	scripts map[string]string
	LK      sync.RWMutex
	watcher *fsnotify.Watcher
	update  chan string
	done    chan struct{}
}

func (bucket *LuaBucket) SetDir(dir string) {
	bucket.LK.Lock()
	defer bucket.LK.Unlock()
	bucket.dir = dir
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Error("VM watcher error %v", err)
	}
	bucket.watcher = watcher
}

func (bucket *LuaBucket) Done() {
	go func() {
		bucket.done <- struct{}{}
	}()
}

// 修改后动态更新
func (bucket *LuaBucket) Watch() {
	bucket.done = make(chan struct{})
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Error("========================== panic in watcher, hotupdate error =================================== \n %s\n", debug.Stack())
			}
		}()
		for {
			select {
			case event, ok := <-bucket.watcher.Events:
				if !ok {
					return
				}
				if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
					log.Release("modified file: %s", event.Name)
					// 重新加载脚本
					bucket.LK.Lock()
					// replace \ to /
					event.Name = strings.Replace(event.Name, "\\", "/", -1)
					_, ok := bucket.scripts[event.Name]
					bucket.LK.Unlock()
					if ok {
						fmt.Println("ready to hot update, ", event.Op)
						bucket.hot(event.Name)
					} else {
						endFix := event.Name[len(event.Name)-4:]
						if event.Op&fsnotify.Create == fsnotify.Create && endFix == ".lua" {
							fmt.Println("new lua file ", event.Name)
							bucket.hot(event.Name)
						}
					}
				}
			case err, ok := <-bucket.watcher.Errors:
				if !ok {
					return
				}
				log.Error("error:", err)
			case <-bucket.done:
				log.Release("bucket watch end")
				bucket.watcher.Close()
			}
		}
	}()
	err := bucket.watcher.Add(bucket.dir)
	if err != nil {
		log.Error("watch error %v", err)
	} else {
		log.Release("add watch dir %s", bucket.dir)
	}
}

func (bucket *LuaBucket) Load(up chan string) (map[string]string, error) {
	bucket.LK.Lock()
	defer bucket.LK.Unlock()
	bucket.scripts = make(map[string]string)
	err := bucket.read(bucket.dir)
	if err != nil {
		return nil, err
	}
	bucket.update = up
	return bucket.scripts, nil
}

func (bucket *LuaBucket) read(dir string) error {
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		return err
	}
	for _, f := range files {
		if f.IsDir() {
			if err := bucket.read(dir + "/" + f.Name()); err != nil {
				return err
			}
		}
		subfix := f.Name()[len(f.Name())-4:]
		if subfix == ".lua" {
			path := dir + "/" + f.Name()
			fmt.Println("bucket loaded lua file =>", path)
			data, err := ioutil.ReadFile(path)
			if err != nil {
				log.Error("Read file %s error %s \n", f.Name(), err)
			} else {
				bucket.scripts[path] = string(data)
			}
		}
	}
	return nil
}

func (bucket *LuaBucket) hot(filePath string) {
	bucket.LK.Lock()
	defer bucket.LK.Unlock()
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Error("hot read file error %s\n", err)
	} else {
		bucket.scripts[filePath] = string(data)
		tk := time.Tick(time.Second)
		select {
		// 写入更新
		case bucket.update <- string(data):
		case <-tk: // 更新超时
			bucket.done <- struct{}{}
		}
	}
}
