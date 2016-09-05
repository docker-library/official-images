package templatelib

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"
	"text/template"
)

func swapStringsFuncBoolArgsOrder(a func(string, string) bool) func(string, string) bool {
	return func(str1 string, str2 string) bool {
		return a(str2, str1)
	}
}

func thingsActionFactory(name string, actOnFirst bool, action func([]interface{}, interface{}) interface{}) func(args ...interface{}) interface{} {
	return func(args ...interface{}) interface{} {
		if len(args) < 1 {
			panic(fmt.Sprintf(`%q requires at least one argument`, name))
		}

		actArgs := []interface{}{}
		for _, val := range args {
			v := reflect.ValueOf(val)

			switch v.Kind() {
			case reflect.Slice, reflect.Array:
				for i := 0; i < v.Len(); i++ {
					actArgs = append(actArgs, v.Index(i).Interface())
				}
			default:
				actArgs = append(actArgs, v.Interface())
			}
		}

		var arg interface{}
		if actOnFirst {
			arg = actArgs[0]
			actArgs = actArgs[1:]
		} else {
			arg = actArgs[len(actArgs)-1]
			actArgs = actArgs[:len(actArgs)-1]
		}

		return action(actArgs, arg)
	}
}

func stringsActionFactory(name string, actOnFirst bool, action func([]string, string) string) func(args ...interface{}) interface{} {
	return thingsActionFactory(name, actOnFirst, func(args []interface{}, arg interface{}) interface{} {
		str := arg.(string)
		strs := []string{}
		for _, val := range args {
			strs = append(strs, val.(string))
		}
		return action(strs, str)
	})
}

func stringsModifierActionFactory(a func(string, string) string) func([]string, string) string {
	return func(strs []string, str string) string {
		for _, mod := range strs {
			str = a(str, mod)
		}
		return str
	}
}

// TODO write some tests for these

var FuncMap = template.FuncMap{
	"hasPrefix": swapStringsFuncBoolArgsOrder(strings.HasPrefix),
	"hasSuffix": swapStringsFuncBoolArgsOrder(strings.HasSuffix),

	"ternary": func(truthy interface{}, falsey interface{}, val interface{}) interface{} {
		if t, ok := template.IsTrue(val); !ok {
			panic(fmt.Sprintf(`template.IsTrue(%+v) says things are NOT OK`, val))
		} else if t {
			return truthy
		} else {
			return falsey
		}
	},

	"first": thingsActionFactory("first", true, func(args []interface{}, arg interface{}) interface{} { return arg }),
	"last":  thingsActionFactory("last", false, func(args []interface{}, arg interface{}) interface{} { return arg }),

	"json": func(v interface{}) (string, error) {
		j, err := json.Marshal(v)
		return string(j), err
	},
	"join":         stringsActionFactory("join", true, strings.Join),
	"trimPrefixes": stringsActionFactory("trimPrefixes", false, stringsModifierActionFactory(strings.TrimPrefix)),
	"trimSuffixes": stringsActionFactory("trimSuffixes", false, stringsModifierActionFactory(strings.TrimSuffix)),
	"replace": stringsActionFactory("replace", false, func(strs []string, str string) string {
		return strings.NewReplacer(strs...).Replace(str)
	}),
}
