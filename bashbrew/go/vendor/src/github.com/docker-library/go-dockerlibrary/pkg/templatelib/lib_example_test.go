package templatelib_test

import (
	"os"
	"text/template"

	"github.com/docker-library/go-dockerlibrary/pkg/templatelib"
)

func Example_prefixSuffix() {
	tmpl, err := template.New("github-or-html").Funcs(templatelib.FuncMap).Parse(`
		{{- . -}}

		{{- if hasPrefix "https://github.com/" . -}}
			{{- " " -}} GitHub
		{{- end -}}

		{{- if hasSuffix ".html" . -}}
			{{- " " -}} HTML
		{{- end -}}

		{{- "\n" -}}
	`)
	if err != nil {
		panic(err)
	}

	err = tmpl.Execute(os.Stdout, "https://github.com/example/example")
	if err != nil {
		panic(err)
	}

	err = tmpl.Execute(os.Stdout, "https://example.com/test.html")
	if err != nil {
		panic(err)
	}

	err = tmpl.Execute(os.Stdout, "https://example.com")
	if err != nil {
		panic(err)
	}

	err = tmpl.Execute(os.Stdout, "https://github.com/example/example/raw/master/test.html")
	if err != nil {
		panic(err)
	}

	// Output:
	// https://github.com/example/example GitHub
	// https://example.com/test.html HTML
	// https://example.com
	// https://github.com/example/example/raw/master/test.html GitHub HTML
}

func Example_ternary() {
	tmpl, err := template.New("huge-if-true").Funcs(templatelib.FuncMap).Parse(`
		{{- range $a := . -}}
			{{ printf "%#v: %s\n" $a (ternary "HUGE" "not so huge" $a) }}
		{{- end -}}
	`)

	err = tmpl.Execute(os.Stdout, []interface{}{
		true,
		false,
		"true",
		"false",
		"",
		nil,
		1,
		0,
		9001,
		[]bool{},
		[]bool{false},
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// true: HUGE
	// false: not so huge
	// "true": HUGE
	// "false": HUGE
	// "": not so huge
	// <nil>: not so huge
	// 1: HUGE
	// 0: not so huge
	// 9001: HUGE
	// []bool{}: not so huge
	// []bool{false}: HUGE
}

func Example_firstLast() {
	tmpl, err := template.New("first-and-last").Funcs(templatelib.FuncMap).Parse(`First: {{ . | first }}, Last: {{ . | last }}`)

	err = tmpl.Execute(os.Stdout, []interface{}{
		"a",
		"b",
		"c",
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// First: a, Last: c
}

func Example_json() {
	tmpl, err := template.New("json").Funcs(templatelib.FuncMap).Parse(`
		{{- json . -}}
	`)

	err = tmpl.Execute(os.Stdout, map[string]interface{}{
		"a": []string{"1", "2", "3"},
		"b": map[string]bool{"1": true, "2": false, "3": true},
		"c": nil,
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// {"a":["1","2","3"],"b":{"1":true,"2":false,"3":true},"c":null}
}

func Example_join() {
	tmpl, err := template.New("join").Funcs(templatelib.FuncMap).Parse(`
		Array: {{ . | join ", " }}{{ "\n" -}}
		Args: {{ join ", " "a" "b" "c" -}}
	`)

	err = tmpl.Execute(os.Stdout, []string{
		"1",
		"2",
		"3",
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// Array: 1, 2, 3
	// Args: a, b, c
}

func Example_trimReplaceGitToHttps() {
	tmpl, err := template.New("git-to-https").Funcs(templatelib.FuncMap).Parse(`
		{{- range . -}}
			{{- . | replace "git://" "https://" | trimSuffixes ".git" }}{{ "\n" -}}
		{{- end -}}
	`)

	err = tmpl.Execute(os.Stdout, []string{
		"git://github.com/jsmith/some-repo.git",
		"https://github.com/jsmith/some-repo.git",
		"https://github.com/jsmith/some-repo",
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// https://github.com/jsmith/some-repo
	// https://github.com/jsmith/some-repo
	// https://github.com/jsmith/some-repo
}

func Example_trimReplaceGitToGo() {
	tmpl, err := template.New("git-to-go").Funcs(templatelib.FuncMap).Parse(`
		{{- range . -}}
			{{- . | trimPrefixes "git://" "http://" "https://" "ssh://" | trimSuffixes ".git" }}{{ "\n" -}}
		{{- end -}}
	`)

	err = tmpl.Execute(os.Stdout, []string{
		"git://github.com/jsmith/some-repo.git",
		"https://github.com/jsmith/some-repo.git",
		"https://github.com/jsmith/some-repo",
		"ssh://github.com/jsmith/some-repo.git",
		"github.com/jsmith/some-repo",
	})
	if err != nil {
		panic(err)
	}

	// Output:
	// github.com/jsmith/some-repo
	// github.com/jsmith/some-repo
	// github.com/jsmith/some-repo
	// github.com/jsmith/some-repo
	// github.com/jsmith/some-repo
}

func Example_getenv() {
	tmpl, err := template.New("getenv").Funcs(templatelib.FuncMap).Parse(`
		The FOO environment variable {{ getenv "FOO" "is set" "is not set" }}. {{- "\n" -}}
		BAR: {{ getenv "BAR" "not set" }} {{- "\n" -}}
		BAZ: {{ getenv "BAZ" "not set" }} {{- "\n" -}}
		{{- $env := getenv "FOOBARBAZ" -}}
		{{- if eq $env "" -}}
			FOOBARBAZ {{- "\n" -}}
		{{- end -}}
	`)

	os.Setenv("FOO", "")
	os.Unsetenv("BAR")
	os.Setenv("BAZ", "foobar")
	os.Unsetenv("FOOBARBAZ")

	err = tmpl.Execute(os.Stdout, nil)
	if err != nil {
		panic(err)
	}

	// Output:
	// The FOO environment variable is not set.
	// BAR: not set
	// BAZ: foobar
	// FOOBARBAZ
}
