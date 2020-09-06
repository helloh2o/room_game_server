package vm

type CallData struct {
	Function string
	Args     []interface{}
	Result   chan CallResult
	Nresult  int
}

func NewCallData(function string, Args []interface{}, nresult int) CallData {
	return CallData{Function: function, Result: make(chan CallResult, 1), Args: Args, Nresult: nresult}
}

type CallResult struct {
	Ok     bool
	Reason string
	Data   []interface{}
}
