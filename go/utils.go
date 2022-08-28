package main

import (
	"reflect"

	"github.com/jmoiron/sqlx"
)

type database interface {
	Select(dest interface{}, query string, args ...interface{}) error
}

func SelectIn(db database, dest interface{}, query string, args ...interface{}) error {
	for _, a := range args {
		if v, ok := asSliceForIn(a); ok {
			if v.Len() == 0 /* listがlen=0のチェック */ {
				return nil
			}
		}
		if a == nil /* nilの場合もチェック */ {
			return nil
		}
	}

	nquery, nargs, err := sqlx.In(query, args...)
	if err != nil {
		return err
	}

	for _, a := range nargs {
		if a == nil {
			return nil
		}
	}

	return db.Select(dest, nquery, nargs...)
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
