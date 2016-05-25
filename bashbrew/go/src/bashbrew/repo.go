package main

import (
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/docker-library/go-dockerlibrary/manifest"
	"pault.ag/go/topsort"
)

func latestizeRepoTag(repoTag string) string {
	if repoTag != "scratch" && strings.IndexRune(repoTag, ':') < 0 {
		return repoTag + ":latest"
	}
	return repoTag
}

type Repo struct {
	RepoName string
	TagName  string
	Manifest *manifest.Manifest2822
	TagEntry *manifest.Manifest2822Entry
}

func (r Repo) SkipConstraints(entry manifest.Manifest2822Entry) bool {
	repoTag := r.RepoName + ":" + entry.Tags[0]

	if len(entry.Constraints) == 0 {
		if exclusiveConstraints {
			fmt.Fprintf(os.Stderr, "skipping %q (due to exclusive constraints)\n", repoTag)
			return true
		}
		return false
	}

	for _, constraint := range constraints {
		for _, eConstraint := range entry.Constraints {
			not := false
			if eConstraint[0] == '!' {
				not = true
				eConstraint = eConstraint[1:]
			}
			if constraint == eConstraint {
				if not {
					fmt.Fprintf(os.Stderr, "skipping %q (due to constraint %q)\n", repoTag, constraint)
				}
				return not
			}
		}
	}

	return true
}

func (r Repo) Entries() []manifest.Manifest2822Entry {
	if r.TagName == "" {
		return r.Manifest.Entries
	} else {
		return []manifest.Manifest2822Entry{*r.Manifest.GetTag(r.TagName)}
	}
}

func (r Repo) SortedEntries() ([]manifest.Manifest2822Entry, error) {
	entries := r.Entries()

	if noSortFlag || len(entries) <= 1 {
		return entries, nil
	}

	network := topsort.NewNetwork()

	for i, entry := range entries {
		for _, tag := range r.Tags("", false, entry) {
			network.AddNode(tag, &entries[i])
		}
	}

	for _, entry := range entries {
		from, err := r.DockerFrom(&entry)
		if err != nil {
			return nil, err
		}
		for _, tag := range r.Tags("", false, entry) {
			network.AddEdgeIfExists(from, tag)
		}
	}

	nodes, err := network.Sort()
	if err != nil {
		return nil, err
	}

	seen := map[*manifest.Manifest2822Entry]bool{}
	ret := []manifest.Manifest2822Entry{}
	for _, node := range nodes {
		entry := node.Value.(*manifest.Manifest2822Entry)
		if seen[entry] {
			// TODO somehow reconcile "a:a -> b:b, b:b -> a:c"
			continue
		}
		ret = append(ret, *entry)
		seen[entry] = true
	}

	return ret, nil
}

func (r Repo) Tags(namespace string, uniq bool, entry manifest.Manifest2822Entry) []string {
	tagRepo := path.Join(namespace, r.RepoName)
	ret := []string{}
	for i, tag := range entry.Tags {
		if uniq && i > 0 {
			break
		}
		ret = append(ret, tagRepo+":"+tag)
	}
	return ret
}

var repoCache = map[string]*Repo{}

func fetch(repo string) (*Repo, error) {
	if r, ok := repoCache[repo]; ok {
		return r, nil
	}

	repoName, tagName, man, err := manifest.Fetch(defaultLibrary, repo)
	if err != nil {
		return nil, err
	}

	r := &Repo{
		RepoName: repoName,
		TagName:  tagName,
		Manifest: man,
	}
	if tagName != "" {
		r.TagEntry = man.GetTag(tagName)
	}
	repoCache[repo] = r
	return r, nil
}
