package control_test

import (
	"strings"
	"testing"

	"pault.ag/go/debian/control"
	"pault.ag/go/debian/dependency"
	"pault.ag/go/debian/version"
)

type TestStruct struct {
	Value      string `required:"true"`
	ValueTwo   string `control:"Value-Two"`
	ValueThree []string
	Depends    dependency.Dependency
	Version    version.Version
	Arch       dependency.Arch
	Arches     []dependency.Arch
	Fnord      struct {
		FooBar string `control:"Fnord-Foo-Bar"`
	}
}

func TestBasicUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Foo-Bar: baz
`)))
	assert(t, foo.Value == "foo")
}

func TestBasicArrayUnmarshal(t *testing.T) {
	foo := []TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Foo-Bar: baz

Value: Bar

Value: Baz
`)))
	assert(t, len(foo) == 3)
	assert(t, foo[0].Value == "foo")
}

func TestTagUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Value-Two: baz
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.ValueTwo == "baz")
}

func TestDependsUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Depends: foo, bar
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.Depends.Relations[0].Possibilities[0].Name == "foo")

	/* Actually invalid below */
	notok(t, control.Unmarshal(&foo, strings.NewReader(`Depends: foo (>= 1.0) (<= 1.0)
`)))
}

func TestVersionUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Version: 1.0-1
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.Version.Revision == "1")
}

func TestArchUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Arch: amd64
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.Arch.CPU == "amd64")

	foo = TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Arches: amd64 sparc any
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.Arches[0].CPU == "amd64")
	assert(t, foo.Arches[1].CPU == "sparc")
	assert(t, foo.Arches[2].CPU == "any")
}

func TestNestedUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
Fnord-Foo-Bar: Thing
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.Fnord.FooBar == "Thing")
}

func TestListUnmarshal(t *testing.T) {
	foo := TestStruct{}
	isok(t, control.Unmarshal(&foo, strings.NewReader(`Value: foo
ValueThree: foo bar baz
`)))
	assert(t, foo.Value == "foo")
	assert(t, foo.ValueThree[0] == "foo")
}

func TestRequiredUnmarshal(t *testing.T) {
	foo := TestStruct{}
	notok(t, control.Unmarshal(&foo, strings.NewReader(`Foo-Bar: baz
`)))
}
