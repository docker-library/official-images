package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"strings"
	"text/template"

	"github.com/codegangsta/cli"
	"github.com/docker-library/go-dockerlibrary/pkg/templatelib"
)

var DefaultCatFormat = `
{{- if i }}{{ "\n\n" }}{{ end -}}
{{- .TagName | ternary (.Manifest.GetTag .TagName) .Manifest -}}
`

func cmdCat(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	format := c.String("format")
	formatFile := c.String("format-file")

	templateName := "--format"
	tmplMultiErr := fmt.Errorf(`failed parsing --format %q`, format)
	if formatFile != "" {
		b, err := ioutil.ReadFile(formatFile)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed reading --format-file %q`, formatFile), err)
		}
		templateName = formatFile
		tmplMultiErr = fmt.Errorf(`failed parsing --format-file %q`, formatFile)
		format = string(b)
	}

	var i int
	tmpl, err := template.New(templateName).Funcs(templatelib.FuncMap).Funcs(template.FuncMap{
		"i": func() int {
			return i
		},
		"arch": func() string {
			return arch
		},
		"archNamespace": func(arch string) string {
			return archNamespaces[arch]
		},
	}).Parse(format)
	if err != nil {
		return cli.NewMultiError(tmplMultiErr, err)
	}

	var repo string
	for i, repo = range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		buf := &bytes.Buffer{}
		err = tmpl.ExecuteTemplate(buf, templateName, r)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed executing template`), err)
		}
		out := buf.String()
		fmt.Print(out)
		if !strings.HasSuffix(out, "\n") {
			fmt.Println()
		}
	}

	return nil
}
