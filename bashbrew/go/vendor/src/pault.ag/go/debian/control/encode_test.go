package control_test

import (
	"bytes"
	"strings"
	"testing"

	"pault.ag/go/debian/control"
	"pault.ag/go/debian/dependency"
	"pault.ag/go/debian/version"
)

type TestMarshalStruct struct {
	Foo string
}

type SomeComplexStruct struct {
	control.Paragraph

	Version    version.Version
	Dependency dependency.Dependency
}

type TestParaMarshalStruct struct {
	control.Paragraph
	Foo string
}

func TestExtraMarshal(t *testing.T) {
	el := TestParaMarshalStruct{}

	isok(t, control.Unmarshal(&el, strings.NewReader(`Foo: test
X-A-Test: Foo
`)))

	assert(t, el.Foo == "test")

	writer := bytes.Buffer{}
	isok(t, control.Marshal(&writer, el))
	assert(t, writer.String() == `Foo: test
X-A-Test: Foo
`)
}

func TestBasicMarshal(t *testing.T) {
	testStruct := TestMarshalStruct{Foo: "Hello"}

	writer := bytes.Buffer{}
	err := control.Marshal(&writer, testStruct)
	isok(t, err)

	assert(t, writer.String() == `Foo: Hello
`)

	writer = bytes.Buffer{}
	err = control.Marshal(&writer, []TestMarshalStruct{
		testStruct,
	})
	isok(t, err)
	assert(t, writer.String() == `Foo: Hello
`)

	writer = bytes.Buffer{}
	err = control.Marshal(&writer, []TestMarshalStruct{
		testStruct,
		testStruct,
	})
	isok(t, err)

	assert(t, writer.String() == `Foo: Hello

Foo: Hello
`)
}

func TestExternalMarshal(t *testing.T) {
	testStruct := SomeComplexStruct{}
	isok(t, control.Unmarshal(&testStruct, strings.NewReader(`Version: 1.0-1
Dependency: foo, bar
X-Foo: bar

`)))
	writer := bytes.Buffer{}

	err := control.Marshal(&writer, testStruct)
	isok(t, err)

	assert(t, testStruct.Dependency.Relations[0].Possibilities[0].Name == "foo")

	assert(t, writer.String() == `Version: 1.0-1
Dependency: foo, bar
X-Foo: bar
`)
}

func TestMultilineMarshal(t *testing.T) {
	testStruct := TestMarshalStruct{Foo: `Hello
This
Is

A Test`}
	writer := bytes.Buffer{}

	err := control.Marshal(&writer, testStruct)
	isok(t, err)

	assert(t, writer.String() == `Foo: Hello
 This
 Is
 .
 A Test
`)
}

// vim: foldmethod=marker
