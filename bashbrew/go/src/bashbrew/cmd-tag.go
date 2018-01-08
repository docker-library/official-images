package main

import (
	"fmt"
	"path"

	"github.com/codegangsta/cli"
)

func cmdTag(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	uniq := c.Bool("uniq")
	namespace := c.String("namespace")
	dryRun := c.Bool("dry-run")

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "tag"`)
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

			for _, tag := range r.Tags("", uniq, entry) {
				namespacedTag := path.Join(namespace, tag)
				fmt.Printf("Tagging %s\n", namespacedTag)
				if !dryRun {
					err = dockerTag(tag, namespacedTag)
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed tagging %q as %q`, tag, namespacedTag), err)
					}
				}
			}
		}
	}

	return nil
}
