package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	// 修改自己机子上client目录的绝对地址，然后自动web服务器， 浏览器打开http://localhost:8080/ws.html  运行例子
	// http.Handle("/", http.FileServer(http.Dir("D:/Dev/go/src/server/client")))
	path, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}
	http.Handle("/", http.FileServer(http.Dir(path+"/client")))
	http.ListenAndServe(":8080", nil)
}
