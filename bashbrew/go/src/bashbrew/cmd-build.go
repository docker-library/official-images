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

	repos, err = sortRepos(repos, true)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed sorting repo list`), err)
	}

	uniq := c.Bool("uniq")
	pull := c.String("pull")
	switch pull {
	case "always", "missing", "never":
		// legit
	default:
		return fmt.Errorf(`invalid value for --pull: %q`, pull)
	}
	dryRun := c.Bool("dry-run")

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		entries, err := r.SortedEntries(true)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed sorting entries list for %q`, repo), err)
		}

		for _, entry := range entries {
			if r.SkipConstraints(entry) {
				continue
			}

			froms, err := r.DockerFroms(entry)
			if err != nil {
				return cli.NewMultiError(fmt.Errorf(`failed fetching/scraping FROM for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
			}

			for _, from := range froms {
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
						// TODO detect if "from" is something we've built (ie, "python:3-onbuild" is "FROM python:3" but we don't want to pull "python:3" if we "bashbrew build python")
						fmt.Printf("Pulling %s (%s)\n", from, r.EntryIdentifier(entry))
						if !dryRun {
							dockerPull(from)
						}
					}
				}
			}

			cacheTag, err := r.DockerCacheName(entry)
			if err != nil {
				return cli.NewMultiError(fmt.Errorf(`failed calculating "cache hash" for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
			}

			// check whether we've already built this artifact
			_, err = dockerInspect("{{.Id}}", cacheTag)
			if err != nil {
				fmt.Printf("Building %s (%s)\n", cacheTag, r.EntryIdentifier(entry))
				if !dryRun {
					commit, err := r.fetchGitRepo(arch, entry)
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed fetching git repo for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
					}

					archive, err := gitArchive(commit, entry.ArchDirectory(arch))
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed generating git archive for %q (tags %q)`, r.RepoName, entry.TagsString()), err)
					}
					defer archive.Close()

					// TODO use "meta.StageNames" to do "docker build --target" so we can tag intermediate stages too for cache (streaming "git archive" directly to "docker build" makes that a little hard to accomplish without re-streaming)

					err = dockerBuild(cacheTag, entry.ArchFile(arch), archive)
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed building %q (tags %q)`, r.RepoName, entry.TagsString()), err)
					}
					archive.Close() // be sure this happens sooner rather than later (defer might take a while, and we want to reap zombies more aggressively)
				}
			} else {
				fmt.Printf("Using %s (%s)\n", cacheTag, r.EntryIdentifier(entry))
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				fmt.Printf("Tagging %s\n", tag)
				if !dryRun {
					err := dockerTag(cacheTag, tag)
					if err != nil {
						return cli.NewMultiError(fmt.Errorf(`failed tagging %q as %q`, cacheTag, tag), err)
					}
				}
			}
		}
	}

	return nil
}
