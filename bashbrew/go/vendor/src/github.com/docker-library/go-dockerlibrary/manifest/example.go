// +build ignore

package main

import (
	"bufio"
	"fmt"
	"strings"

	"github.com/docker-library/go-dockerlibrary/manifest"
)

func main() {
	// TODO comment parsing
	man, err := manifest.Parse(bufio.NewReader(strings.NewReader(`# RFC 2822

	# I LOVE CAKE

Maintainers: InfoSiftr <github@infosiftr.com> (@infosiftr),
             Johan Euphrosine <proppy@google.com> (@proppy)
GitRepo: https://github.com/docker-library/golang.git
GitFetch: refs/heads/master


 # hi


 	 # blasphemer


# Go 1.6
Tags: 1.6.1, 1.6, 1, latest
GitCommit: 0ce80411b9f41e9c3a21fc0a1bffba6ae761825a
Directory: 1.6


# Go 1.5
Tags: 1.5.3
GitCommit: d7e2a8d90a9b8f5dfd5bcd428e0c33b68c40cc19
Directory: 1.5


Tags: 1.5
GitCommit: d7e2a8d90a9b8f5dfd5bcd428e0c33b68c40cc19
Directory: 1.5


`)))
	if err != nil {
		panic(err)
	}
	fmt.Printf("-------------\n2822:\n%s\n", man)

	man, err = manifest.Parse(bufio.NewReader(strings.NewReader(`
# first set
a: b@c d
e: b@c d

 # second set
f: g@h
i: g@h j
`)))
	if err != nil {
		panic(err)
	}
	fmt.Printf("-------------\nline-based:\n%v\n", man)
}
