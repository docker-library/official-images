package main

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"github.com/docker-library/go-dockerlibrary/manifest"
)

func repos(all bool, args ...string) ([]string, error) {
	ret := []string{}

	if all {
		dir, err := os.Open(defaultLibrary)
		if err != nil {
			return nil, err
		}
		names, err := dir.Readdirnames(-1)
		dir.Close()
		if err != nil {
			return nil, err
		}
		sort.Strings(names)
		for _, name := range names {
			ret = append(ret, filepath.Join(defaultLibrary, name))
		}
	}

	ret = append(ret, args...)

	if len(ret) < 1 {
		return nil, fmt.Errorf(`need at least one repo (either explicitly or via "--all")`)
	}

	return ret, nil
}

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

	// if "TagName" refers to a SharedTag, "TagEntry" will be the first match, this will contain all matches (otherwise it will be just "TagEntry")
	TagEntries []*manifest.Manifest2822Entry
}

func (r Repo) Identifier() string {
	if r.TagEntry != nil {
		return r.EntryIdentifier(r.TagEntry)
	}
	return r.RepoName
}

func (r Repo) EntryIdentifier(entry *manifest.Manifest2822Entry) string {
	return r.RepoName + ":" + entry.Tags[0]
}

// create a new "Repo" object representing a single "Manifest2822Entry" object
func (r Repo) EntryRepo(entry *manifest.Manifest2822Entry) *Repo {
	return &Repo{
		RepoName:   r.RepoName,
		TagName:    entry.Tags[0],
		Manifest:   r.Manifest,
		TagEntry:   entry,
		TagEntries: []*manifest.Manifest2822Entry{entry},
	}
}

var haveOutputSkippedMessage = map[string]bool{}

func (r Repo) SkipConstraints(entry *manifest.Manifest2822Entry) bool {
	repoTag := r.RepoName + ":" + entry.Tags[0]

	// TODO decide if "arch" and "constraints" should be handled separately (but probably not)
	if !entry.HasArchitecture(arch) {
		if !haveOutputSkippedMessage[repoTag] {
			fmt.Fprintf(os.Stderr, "skipping %q (due to architecture %q; only %q supported)\n", repoTag, arch, entry.ArchitecturesString())
			haveOutputSkippedMessage[repoTag] = true
		}
		return true
	}

	if len(entry.Constraints) == 0 {
		if exclusiveConstraints {
			if !haveOutputSkippedMessage[repoTag] {
				fmt.Fprintf(os.Stderr, "skipping %q (due to exclusive constraints)\n", repoTag)
				haveOutputSkippedMessage[repoTag] = true
			}
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
		if !haveOutputSkippedMessage[repoTag] {
			fmt.Fprintf(os.Stderr, "skipping %q (due to unsatisfactory constraints %q)\n", repoTag, unsatisfactory)
			haveOutputSkippedMessage[repoTag] = true
		}
		return true
	}

	return false
}

func (r Repo) Entries() []*manifest.Manifest2822Entry {
	if r.TagName == "" {
		ret := []*manifest.Manifest2822Entry{}
		for i := range r.Manifest.Entries {
			ret = append(ret, &r.Manifest.Entries[i])
		}
		return ret
	} else {
		return r.TagEntries
	}
}

func (r Repo) Tags(namespace string, uniq bool, entry *manifest.Manifest2822Entry) []string {
	tagRepo := path.Join(namespace, r.RepoName)
	ret := []string{}
	tags := append([]string{}, entry.Tags...)
	tags = append(tags, entry.SharedTags...)
	for i, tag := range tags {
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
		if r.TagEntry == nil {
			// must be a SharedTag
			r.TagEntries = man.GetSharedTag(tagName)
			r.TagEntry = r.TagEntries[0]
		} else {
			// not a SharedTag, backfill TagEntries
			r.TagEntries = []*manifest.Manifest2822Entry{r.TagEntry}
		}
	}
	repoCache[repo] = r
	return r, nil
}
