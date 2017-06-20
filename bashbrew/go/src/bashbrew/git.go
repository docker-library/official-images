package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/docker-library/go-dockerlibrary/manifest"
	"github.com/docker-library/go-dockerlibrary/pkg/execpipe"
)

func gitCache() string {
	return filepath.Join(defaultCache, "git")
}

func gitCommand(args ...string) *exec.Cmd {
	if debugFlag {
		fmt.Printf("$ git %q\n", args)
	}
	cmd := exec.Command("git", args...)
	cmd.Dir = gitCache()
	return cmd
}

func git(args ...string) ([]byte, error) {
	out, err := gitCommand(args...).Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return nil, fmt.Errorf("%v\ncommand: git %q\n%s", ee, args, string(ee.Stderr))
		}
	}
	return out, err
}

func ensureGitInit() error {
	err := os.MkdirAll(gitCache(), os.ModePerm)
	if err != nil {
		return err
	}
	git("init", "--quiet", "--bare", ".") // ignore errors -- just make sure the repo exists
	git("config", "gc.auto", "0")         // ensure garbage collection is disabled so we keep dangling commits
	return nil
}

func getGitCommit(commit string) (string, error) {
	out, err := git("rev-parse", commit+"^{commit}")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func gitStream(args ...string) (io.ReadCloser, error) {
	return execpipe.Run(gitCommand(args...))
}

func gitArchive(commit string, dir string) (io.ReadCloser, error) {
	dir = path.Clean(dir)
	if dir == "." {
		dir = ""
	} else {
		dir += "/"
	}
	return gitStream("archive", "--format=tar", commit+":"+dir)
}

func gitShow(commit string, file string) (io.ReadCloser, error) {
	return gitStream("show", commit+":"+path.Clean(file))
}

// for gitNormalizeForTagUsage()
// see http://stackoverflow.com/a/26382358/433558
var (
	gitBadTagChars = regexp.MustCompile(`(?:` + strings.Join([]string{
		`[^0-9a-zA-Z/._-]+`,

		// They can include slash `/` for hierarchical (directory) grouping, but no slash-separated component can begin with a dot `.` or end with the sequence `.lock`.
		`/[.]+`,
		`[.]lock(?:/|$)`,

		// They cannot have two consecutive dots `..` anywhere.
		`[.][.]+`,

		// They cannot end with a dot `.`
		// They cannot begin or end with a slash `/`
		`[/.]+$`,
		`^[/.]+`,
	}, `|`) + `)`)

	gitMultipleSlashes = regexp.MustCompile(`(?://+)`)
)

// strip/replace "bad" characters from text for use as a Git tag
func gitNormalizeForTagUsage(text string) string {
	return gitMultipleSlashes.ReplaceAllString(gitBadTagChars.ReplaceAllString(text, "-"), "/")
}

var gitRepoCache = map[string]string{}

func (r Repo) fetchGitRepo(arch string, entry *manifest.Manifest2822Entry) (string, error) {
	cacheKey := strings.Join([]string{
		entry.ArchGitRepo(arch),
		entry.ArchGitFetch(arch),
		entry.ArchGitCommit(arch),
	}, "\n")
	if commit, ok := gitRepoCache[cacheKey]; ok {
		entry.SetGitCommit(arch, commit)
		return commit, nil
	}

	err := ensureGitInit()
	if err != nil {
		return "", err
	}

	if manifest.GitCommitRegex.MatchString(entry.ArchGitCommit(arch)) {
		commit, err := getGitCommit(entry.ArchGitCommit(arch))
		if err == nil {
			gitRepoCache[cacheKey] = commit
			entry.SetGitCommit(arch, commit)
			return commit, nil
		}
	}

	fetchString := entry.ArchGitFetch(arch) + ":"
	if entry.ArchGitCommit(arch) == "FETCH_HEAD" {
		// fetch remote tag references to a local tag ref so that we can cache them and not re-fetch every time
		localRef := "refs/tags/" + gitNormalizeForTagUsage(cacheKey)
		commit, err := getGitCommit(localRef)
		if err == nil {
			gitRepoCache[cacheKey] = commit
			entry.SetGitCommit(arch, commit)
			return commit, nil
		}
		fetchString += localRef
	} else if entry.ArchGitFetch(arch) == manifest.DefaultLineBasedFetch {
		// backwards compat (see manifest/line-based.go in go-dockerlibrary)
		refBase := "refs/remotes"
		refBaseDir := filepath.Join(gitCache(), refBase)
		err := os.MkdirAll(refBaseDir, os.ModePerm)
		if err != nil {
			return "", err
		}
		tempRefDir, err := ioutil.TempDir(refBaseDir, "temp")
		if err != nil {
			return "", err
		}
		defer os.RemoveAll(tempRefDir)
		tempRef := path.Join(refBase, filepath.Base(tempRefDir))
		fetchString += tempRef + "/*"
		// we create a temporary remote dir so that we can clean it up completely afterwards
	}

	if strings.HasPrefix(entry.ArchGitRepo(arch), "git://github.com/") {
		fmt.Fprintf(os.Stderr, "warning: insecure protocol git:// detected: %s\n", entry.ArchGitRepo(arch))
		entry.SetGitRepo(arch, strings.Replace(entry.ArchGitRepo(arch), "git://", "https://", 1))
	}

	_, err = git("fetch", "--quiet", "--no-tags", entry.ArchGitRepo(arch), fetchString)
	if err != nil {
		return "", err
	}

	commit, err := getGitCommit(entry.ArchGitCommit(arch))
	if err != nil {
		return "", err
	}

	_, err = git("tag", "--force", r.RepoName+"/"+entry.Tags[0], commit)
	if err != nil {
		return "", err
	}

	gitRepoCache[cacheKey] = commit
	entry.SetGitCommit(arch, commit)
	return commit, nil
}
