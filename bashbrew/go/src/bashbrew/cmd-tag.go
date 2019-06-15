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
	targetNamespace := c.String("target-namespace")
	dryRun := c.Bool("dry-run")

	if targetNamespace == "" {
		return fmt.Errorf(`"--target-namespace" is a required flag for "tag"`)
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
				sourceTag := path.Join(namespace, tag)
				targetTag := path.Join(targetNamespace, tag)
				fmt.Printf("Tagging %s\n", targetTag)
				if !dryRun {
					err = dockerTag(sourceTag, targetTag)
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed tagging %q as %q`, sourceTag, targetTag), err)
					}
				}
			}
		}
	}

	return nil
}
