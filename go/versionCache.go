package main

import (
	"sync"
)

type MutexVersionMaster struct {
	v   VersionMaster
	mux sync.RWMutex
}

func newMutexVersionMaster() *MutexVersionMaster {
	return &MutexVersionMaster{
		v:   VersionMaster{},
		mux: sync.RWMutex{},
	}
}

func (m *MutexVersionMaster) Get() VersionMaster {
	m.mux.RLock()
	defer m.mux.RUnlock()
	return m.v
}

func (m *MutexVersionMaster) Set(vm VersionMaster) {
	m.mux.Lock()
	m.v = vm
	m.mux.Unlock()
}
