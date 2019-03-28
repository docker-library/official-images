/*
Package templatelib implements a group of useful functions for use with the stdlib text/template package.

Usage:

	tmpl, err := template.New("some-template").Funcs(templatelib.FuncMap).Parse("Hi, {{ join " " .Names }}")
*/
package templatelib
