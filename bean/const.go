package bean

const (
	NULL            = iota
	MAIL_MESSAGE    // 普通文本消息  0
	MAIL_JOIN_UNION // 加入公会邮件  1
)

const (
	CREATE_UNION_FAILED_NAME_EXIST = 1001 // 公会名字存在
	CREATE_UNION_FAILED            = 1002 // 创建公会失败
	NOT_FOUND_UNION                = 1003 // 没有找到公会
	MASTER_ID_ERR                  = 1004 // 公会管理员不匹配
	NOT_FOUND_PLAYER               = 1005 // 没有找到玩家
	TRANSTER_UNION_FAILED          = 1006 // 转让公会十八
	NEED_RE_LOGIN                  = 1007 // 需要重新登录
)
