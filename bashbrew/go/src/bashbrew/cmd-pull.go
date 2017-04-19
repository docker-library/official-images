package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func cmdPull(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	uniq := c.Bool("uniq")
	namespace := c.String("namespace")

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "pull"`)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		for _, entry := range r.Entries() {
			if r.SkipConstraints(entry) {
				continue
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				fmt.Printf("Pulling %s\n", tag)
				err = dockerPull(tag)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed pulling %q`, tag), err)
				}
			}
		}
	}

	return nil
}
