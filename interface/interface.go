package interfaces

import "server/vm"

type VRoom interface {
	GetVm() *vm.VM
}
