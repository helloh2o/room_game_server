package httpsv

import (
	"github.com/kataras/iris"
	"github.com/kataras/iris/context"
	"github.com/kataras/iris/middleware/logger"
	rc "github.com/kataras/iris/middleware/recover"
	"github.com/kataras/iris/sessions"
	"server/leaf/log"
)

var (
	app                    = iris.New()
	cookieNameForSessionID = "xPLay21cookies3SXLUssionnAXeid"
	sess                   = sessions.New(sessions.Config{Cookie: cookieNameForSessionID, AllowReclaim: true})
)

func init() {
	/*app.RegisterView(iris.HTML("./web", ".html").Reload(true))
	app.StaticWeb("/web", "./web")
	app.StaticWeb("/fonts", "./web/fonts")
	app.StaticWeb("/images", "./web/images")*/
	app.Use(rc.New())
	app.Use(logger.New())
	app.UseGlobal(func(ctx context.Context) {
		ctx.Header("Access-Control-Allow-Origin", "*")
		//clientIp := GetClientIp(ctx)
		//log.Printf("Request from ip ==> %s", clientIp)
		ctx.Next()
	})
}
func RunHTTP(addr string) {
	if err := app.Run(iris.Addr(addr), iris.WithoutServerError(iris.ErrServerClosed)); err != nil {
		log.Error("HTTP Server startup error %s", err)
	} else {
		log.Release("HTTP Server startup at %s", addr)
	}
}

type Resp struct {
	Ret   int
	Error string
	DATA  interface{}
}

func GetClientIp(ctx context.Context) string {
	clientIp := ctx.Request().Header.Get("CF-Connecting-IP")
	if clientIp == "" {
		clientIp = ctx.Request().Header.Get("X-Forwarded-For")
		if clientIp == "" {
			clientIp = ctx.RemoteAddr()
		}
	}
	return clientIp
}
