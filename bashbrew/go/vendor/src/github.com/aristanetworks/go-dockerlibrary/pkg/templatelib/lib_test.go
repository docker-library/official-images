package templatelib_test

import (
	"testing"
	"text/template"
	"unsafe"

	"github.com/docker-library/go-dockerlibrary/pkg/templatelib"
)

func TestTernaryPanic(t *testing.T) {
	// one of the only places template.IsTrue will return "false" for the "ok" value is an UnsafePointer (hence this test)

	defer func() {
		if r := recover(); r == nil {
			t.Errorf("Expected panic, executed successfully instead")
		} else if errText, ok := r.(string); !ok || errText != `template.IsTrue(<nil>) says things are NOT OK` {
			t.Errorf("Unexpected panic: %v", errText)
		}
	}()

	tmpl, err := template.New("unsafe-pointer").Funcs(templatelib.FuncMap).Parse(`{{ ternary "true" "false" . }}`)

	err = tmpl.Execute(nil, unsafe.Pointer(uintptr(0)))
	if err != nil {
		t.Errorf("Expected panic, got error instead: %v", err)
	}
}

func TestJoinPanic(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("Expected panic, executed successfully instead")
		} else if errText, ok := r.(string); !ok || errText != `"join" requires at least one argument` {
			t.Errorf("Unexpected panic: %v", r)
		}
	}()

	tmpl, err := template.New("join-no-arg").Funcs(templatelib.FuncMap).Parse(`{{ join }}`)

	err = tmpl.Execute(nil, nil)
	if err != nil {
		t.Errorf("Expected panic, got error instead: %v", err)
	}
}
