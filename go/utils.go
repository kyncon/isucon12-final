package main

import (
	"reflect"

	"github.com/jmoiron/sqlx"
)

type database interface {
	Select(dest interface{}, query string, args ...any) error
}

func SelectIn(db database, dest any, query string, args ...any) error {
	if hasEmptyList(args) {
		return nil
	}

	nquery, nargs, err := sqlx.In(query, args...)
	if err != nil {
		return err
	}

	return db.Select(dest, nquery, nargs...)
}

func hasEmptyList(args ...any) bool {
	for _, a := range args {
		if v, ok := asSliceForIn(a); ok {
			if v.Len() == 0 /* listがlen=0のチェック */ {
				return true
			}
			if a == nil /* nilの場合もチェック */ {
				return true
			}
		}
	}
	return false
}

func asSliceForIn(i interface{}) (v reflect.Value, ok bool) {
	if i == nil {
		return reflect.Value{}, false
	}

	v = reflect.ValueOf(i)
	t := deref(v.Type())

	// Only expand slices
	if t.Kind() != reflect.Slice {
		return reflect.Value{}, false
	}

	// []byte is a driver.Value type so it should not be expanded
	if t == reflect.TypeOf([]byte{}) {
		return reflect.Value{}, false
	}

	return v, true
}

func deref(t reflect.Type) reflect.Type {
	if t.Kind() == reflect.Ptr {
		t = t.Elem()
	}
	return t
}
