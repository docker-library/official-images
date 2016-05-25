package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func cmdBuild(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return err
	}

	repos, err = sortRepos(repos)
	if err != nil {
		return err
	}

	uniq := c.Bool("uniq")
	namespace := c.String("namespace")
	pullMissing := c.Bool("pull-missing")

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return err
		}

		entries, err := r.SortedEntries()
		if err != nil {
			return err
		}

		for _, entry := range entries {
			if r.SkipConstraints(entry) {
				continue
			}

			from, err := r.DockerFrom(&entry)
			if err != nil {
				return err
			}

			if pullMissing {
				_, err := dockerInspect("{{.Id}}", from)
				if err != nil {
					fmt.Printf("Pulling %s (%s)\n", from, r.RepoName)
					dockerPull(from)
				}
			}

			cacheHash, err := r.dockerCacheHash(&entry)
			if err != nil {
				return err
			}

			cacheTag := "bashbrew/cache:" + cacheHash

			// check whether we've already built this artifact
			_, err = dockerInspect("{{.Id}}", cacheTag)
			if err != nil {
				fmt.Printf("Building %s (%s)\n", cacheTag, r.RepoName)

				commit, err := r.fetchGitRepo(&entry)
				if err != nil {
					return err
				}

				archive, err := gitArchive(commit, entry.Directory)
				if err != nil {
					return err
				}
				defer archive.Close()

				err = dockerBuild(cacheTag, archive)
				if err != nil {
					return err
				}
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				fmt.Printf("Tagging %s\n", tag)

				err := dockerTag(cacheTag, tag)
				if err != nil {
					return err
				}
			}
		}
	}

	return nil
}
