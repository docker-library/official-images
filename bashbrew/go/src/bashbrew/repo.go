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

func (r Repo) Identifier() string {
	if r.TagName != "" {
		return r.RepoName + ":" + r.TagName
	}
	return r.RepoName
}

func (r Repo) EntryIdentifier(entry manifest.Manifest2822Entry) string {
	return r.RepoName + ":" + entry.Tags[0]
}

func (r Repo) SkipConstraints(entry manifest.Manifest2822Entry) bool {
	repoTag := r.RepoName + ":" + entry.Tags[0]

	if len(entry.Constraints) == 0 {
		if exclusiveConstraints {
			fmt.Fprintf(os.Stderr, "skipping %q (due to exclusive constraints)\n", repoTag)
		}
		return exclusiveConstraints
	}

	unsatisfactory := []string{}

NextConstraint:
	for _, eConstraint := range entry.Constraints {
		wanted := true
		if eConstraint[0] == '!' {
			wanted = false
			eConstraint = eConstraint[1:]
		}

		for _, gConstraint := range constraints {
			if gConstraint == eConstraint {
				// if we did not want "aufs" ("!aufs") but found it, UNSATISFACTORY
				if !wanted {
					unsatisfactory = append(unsatisfactory, eConstraint)
				}
				continue NextConstraint
			}
		}

		// if we want "aufs" but did not find it, UNSATISFACTORY
		if wanted {
			unsatisfactory = append(unsatisfactory, eConstraint)
		}
	}

	if len(unsatisfactory) > 0 {
		fmt.Fprintf(os.Stderr, "skipping %q (due to unsatisfactory constraints %q)\n", repoTag, unsatisfactory)
		return true
	}

	return false
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
