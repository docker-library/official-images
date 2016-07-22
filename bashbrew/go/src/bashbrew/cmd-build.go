package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func cmdBuild(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	repos, err = sortRepos(repos)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed sorting repo list`, err))
	}

	uniq := c.Bool("uniq")
	namespace := c.String("namespace")
	pull := c.String("pull")
	switch pull {
	case "always", "missing", "never":
		// legit
	default:
		return fmt.Errorf(`invalid value for --pull: %q`, pull)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		entries, err := r.SortedEntries()
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed sorting entries list for %q`, repo), err)
		}

		for _, entry := range entries {
			if r.SkipConstraints(entry) {
				continue
			}

			from, err := r.DockerFrom(&entry)
			if err != nil {
				return cli.NewMultiError(fmt.Errorf(`failed fetching/scraping FROM for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
			}

			if from != "scratch" && pull != "never" {
				doPull := false
				switch pull {
				case "always":
					doPull = true
				case "missing":
					_, err := dockerInspect("{{.Id}}", from)
					doPull = (err != nil)
				default:
					return fmt.Errorf(`unexpected value for --pull: %s`, pull)
				}
				if doPull {
					fmt.Printf("Pulling %s (%s)\n", from, r.EntryIdentifier(entry))
					dockerPull(from)
				}
			}

			cacheTag, err := r.DockerCacheName(&entry)
			if err != nil {
				return cli.NewMultiError(fmt.Errorf(`failed calculating "cache hash" for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
			}

			// check whether we've already built this artifact
			_, err = dockerInspect("{{.Id}}", cacheTag)
			if err != nil {
				fmt.Printf("Building %s (%s)\n", cacheTag, r.EntryIdentifier(entry))

				commit, err := r.fetchGitRepo(&entry)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed fetching git repo for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
				}

				archive, err := gitArchive(commit, entry.Directory)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed generating git archive for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
				}
				defer archive.Close()

				err = dockerBuild(cacheTag, archive)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed building %q (tags %q)`, r.RepoName, entry.TagsString()), err)
				}
				archive.Close() // be sure this happens sooner rather than later (defer might take a while, and we want to reap zombies more aggressively)
			} else {
				fmt.Printf("Using %s (%s)\n", cacheTag, r.EntryIdentifier(entry))
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				fmt.Printf("Tagging %s\n", tag)

				err := dockerTag(cacheTag, tag)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed tagging %q as %q`, cacheTag, tag), err)
				}
			}
		}
	}

	return nil
}
