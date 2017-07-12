package templatelib

import (
	"encoding/json"
	"fmt"
	"os"
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

var FuncMap = template.FuncMap{
	// {{- $isGitHub := hasPrefix "https://github.com/" $url -}}
	// {{- $isHtml := hasSuffix ".html" $url -}}
	"hasPrefix": swapStringsFuncBoolArgsOrder(strings.HasPrefix),
	"hasSuffix": swapStringsFuncBoolArgsOrder(strings.HasSuffix),

	// {{- $hugeIfTrue := .SomeValue | ternary "HUGE" "not so huge" -}}
	// if .SomeValue is truthy, $hugeIfTrue will be "HUGE"
	// (otherwise, "not so huge")
	"ternary": func(truthy interface{}, falsey interface{}, val interface{}) interface{} {
		if t, ok := template.IsTrue(val); !ok {
			panic(fmt.Sprintf(`template.IsTrue(%+v) says things are NOT OK`, val))
		} else if t {
			return truthy
		} else {
			return falsey
		}
	},

	// First Tag: {{- .Tags | first -}}
	// Last Tag:  {{- .Tags | last -}}
	"first": thingsActionFactory("first", true, func(args []interface{}, arg interface{}) interface{} { return arg }),
	"last":  thingsActionFactory("last", false, func(args []interface{}, arg interface{}) interface{} { return arg }),

	// JSON data dump: {{ json . }}
	// (especially nice for taking data and piping it to "jq")
	// (ie "some-tool inspect --format '{{ json . }}' some-things | jq .")
	"json": func(v interface{}) (string, error) {
		j, err := json.Marshal(v)
		return string(j), err
	},

	// Everybody: {{- join ", " .Names -}}
	// Concat: {{- join "/" "https://github.com" "jsmith" "some-repo" -}}
	"join": stringsActionFactory("join", true, strings.Join),

	// {{- $mungedUrl := $url | replace "git://" "https://" | trimSuffixes ".git" -}}
	// turns: git://github.com/jsmith/some-repo.git
	// into: https://github.com/jsmith/some-repo
	"trimPrefixes": stringsActionFactory("trimPrefixes", false, stringsModifierActionFactory(strings.TrimPrefix)),
	"trimSuffixes": stringsActionFactory("trimSuffixes", false, stringsModifierActionFactory(strings.TrimSuffix)),
	"replace": stringsActionFactory("replace", false, func(strs []string, str string) string {
		return strings.NewReplacer(strs...).Replace(str)
	}),

	// {{- getenv "PATH" -}}
	// {{- getenv "HOME" "no HOME set" -}}
	// {{- getenv "HOME" "is set" "is NOT set (or is empty)" -}}
	"getenv": thingsActionFactory("getenv", true, func(args []interface{}, arg interface{}) interface{} {
		var (
			val                  = os.Getenv(arg.(string))
			setVal   interface{} = val
			unsetVal interface{} = ""
		)
		if len(args) == 2 {
			setVal, unsetVal = args[0], args[1]
		} else if len(args) == 1 {
			unsetVal = args[0]
		} else if len(args) != 0 {
			panic(fmt.Sprintf(`expected between 1 and 3 arguments to "getenv", got %d`, len(args)+1))
		}
		if val != "" {
			return setVal
		} else {
			return unsetVal
		}
	}),
}
