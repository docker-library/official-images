package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"text/template"

	"github.com/codegangsta/cli"
)

var DefaultCatFormat = `{{if (ne i 0)}}{{"\n\n"}}{{end}}{{if (eq .TagName "")}}{{.Manifest}}{{else}}{{.Manifest.GetTag .TagName}}{{end}}`

func cmdCat(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return err
	}

	format := c.String("format")

	var i int
	tmpl, err := template.New("--format").Funcs(template.FuncMap{
		"i": func() int {
			return i
		},
		"join": strings.Join,
		"json": func(v interface{}) (string, error) {
			j, err := json.Marshal(v)
			return string(j), err
		},
	}).Parse(format)
	if err != nil {
		return err
	}

	var repo string
	for i, repo = range repos {
		//if i > 0 {
		//	fmt.Println()
		//}

		r, err := fetch(repo)
		if err != nil {
			return err
		}

		err = tmpl.Execute(os.Stdout, r)
		fmt.Println()
	}

	return nil
}
