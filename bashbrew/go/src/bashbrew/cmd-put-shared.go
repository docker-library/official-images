package main

import (
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/codegangsta/cli"
)

func cmdPutShared(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	namespace := c.String("namespace")

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "put-shared"`)
	}

	fmt.Fprintf(os.Stderr, "warning: this subcommand is still a big WIP -- it doesn't do anything yet!\n")

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		// TODO handle all multi-architecture tags first (regardless of whether they have SharedTags)

		targetRepo := path.Join(namespace, r.RepoName)
		for _, group := range r.Manifest.GetSharedTagGroups() {
			// TODO build up a YAML file
			entryTags := []string{}
			for _, entry := range group.Entries {
				entryTags = append(entryTags, entry.Tags[0])
			}
			fmt.Printf("Putting %s (tags %s) <= %s\n", targetRepo, strings.Join(group.SharedTags, ", "), strings.Join(entryTags, ", "))
		}
	}

	return nil
}
