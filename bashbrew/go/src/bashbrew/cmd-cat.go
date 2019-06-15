package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"strings"
	"text/template"

	"github.com/codegangsta/cli"
	"github.com/docker-library/go-dockerlibrary/manifest"
	"github.com/docker-library/go-dockerlibrary/pkg/templatelib"
)

var DefaultCatFormat = `
{{- if i -}}
	{{- "\n\n" -}}
{{- end -}}
{{- with .TagEntries -}}
	{{- range $i, $e := . -}}
		{{- if $i -}}{{- "\n\n" -}}{{- end -}}
		{{- $e -}}
	{{- end -}}
{{- else -}}
	{{- .Manifest -}}
{{- end -}}
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
		"namespace": func() string {
			return namespace
		},
		"archNamespace": func(arch string) string {
			return archNamespaces[arch]
		},
		"archFilter": func(arch string, entriesArg ...interface{}) []manifest.Manifest2822Entry {
			if len(entriesArg) < 1 {
				panic(`"archFilter" requires at least one argument`)
			}
			entries := []manifest.Manifest2822Entry{}
			for _, entryArg := range entriesArg {
				switch v := entryArg.(type) {
				case []*manifest.Manifest2822Entry:
					for _, e := range v {
						entries = append(entries, *e)
					}
				case []manifest.Manifest2822Entry:
					entries = append(entries, v...)
				case manifest.Manifest2822Entry:
					entries = append(entries, v)
				default:
					panic(fmt.Sprintf(`"archFilter" encountered unknown type: %T`, v, v))
				}
			}
			filtered := []manifest.Manifest2822Entry{}
			for _, entry := range entries {
				if entry.HasArchitecture(arch) {
					filtered = append(filtered, entry)
				}
			}
			return filtered
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
			return cli.NewMultiError(fmt.Errorf(`failed executing template for repo %q`, repo), err)
		}
		out := buf.String()
		fmt.Print(out)
		if !strings.HasSuffix(out, "\n") {
			fmt.Println()
		}
	}

	return nil
}
