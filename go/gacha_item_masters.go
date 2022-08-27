package main

import (
	"log"
	"strconv"
	"sync"
)

var gachaItemMasterCache = NewgachaItemMasterCacher()

type gachaItemMasterCacher struct {
	mu   sync.RWMutex
	data map[string][]*GachaItemMaster
}

func NewgachaItemMasterCacher() *gachaItemMasterCacher {
	return &gachaItemMasterCacher{mu: sync.RWMutex{}, data: make(map[string][]*GachaItemMaster)}
}

func (s *gachaItemMasterCacher) Get(key string) ([]*GachaItemMaster, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	res, ok := s.data[key]
	return res, ok
}

func (s *gachaItemMasterCacher) Put(key string, value []*GachaItemMaster) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data[key] = append(s.data[key], value...)
}

func (s *gachaItemMasterCacher) Reset() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data = make(map[string][]*GachaItemMaster)
}

func (s *gachaItemMasterCacher) Initialize(data []*GachaItemMaster) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.data = make(map[string][]*GachaItemMaster)
	for _, d := range data {
		s.data[strconv.Itoa(int(d.GachaID))] = append(s.data[strconv.Itoa(int(d.GachaID))], d)
	}
}

func csvRowToGachaItemMaster(row []string) *GachaItemMaster {
	id, err := strconv.Atoi(row[0])
	if err != nil {
		log.Println(err)
	}
	gachaID, err := strconv.Atoi(row[1])
	if err != nil {
		log.Println(err)
	}
	itemType, err := strconv.Atoi(row[2])
	if err != nil {
		log.Println(err)
	}
	itemID, err := strconv.Atoi(row[3])
	if err != nil {
		log.Println(err)
	}
	amount, err := strconv.Atoi(row[4])
	if err != nil {
		log.Println(err)
	}
	weight, err := strconv.Atoi(row[5])
	if err != nil {
		log.Println(err)
	}
	createdAt, err := strconv.Atoi(row[6])
	if err != nil {
		log.Println(err)
	}
	return &GachaItemMaster{
		ID:        int64(id),
		GachaID:   int64(gachaID),
		ItemType:  itemType,
		ItemID:    int64(itemID),
		Amount:    amount,
		Weight:    weight,
		CreatedAt: int64(createdAt),
	}
}
