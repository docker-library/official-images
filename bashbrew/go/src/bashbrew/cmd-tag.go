package main

import (
	"fmt"
	"path"

	"github.com/codegangsta/cli"
)

func cmdTag(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return err
	}

	uniq := c.Bool("uniq")
	namespace := c.String("namespace")

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "tag"`)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return err
		}

		for _, entry := range r.Entries() {
			for _, tag := range r.Tags("", uniq, entry) {
				namespacedTag := path.Join(namespace, tag)
				fmt.Printf("Tagging %s\n", namespacedTag)
				err = dockerTag(tag, namespacedTag)
				if err != nil {
					return err
				}
			}
		}
	}

	return nil
}
