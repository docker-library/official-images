package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func cmdFrom(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return err
	}

	uniq := c.Bool("uniq")
	namespace := ""

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return err
		}

		for _, entry := range r.Entries() {
			from, err := r.DockerFrom(&entry)
			if err != nil {
				return err
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				fmt.Printf("%s: %s\n", tag, from)
			}
		}
	}

	return nil
}
