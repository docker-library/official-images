package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"github.com/docker-library/go-dockerlibrary/manifest"
	"github.com/docker-library/go-dockerlibrary/pkg/execpipe"
)

func gitCache() string {
	return filepath.Join(defaultCache, "git")
}

func gitCommand(args ...string) *exec.Cmd {
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

var gitRepoCache = map[string]string{}

func (r Repo) fetchGitRepo(entry *manifest.Manifest2822Entry) (string, error) {
	cacheKey := strings.Join([]string{
		entry.GitRepo,
		entry.GitFetch,
		entry.GitCommit,
	}, "\n")
	if commit, ok := gitRepoCache[cacheKey]; ok {
		entry.GitCommit = commit
		return commit, nil
	}

	err := ensureGitInit()
	if err != nil {
		return "", err
	}

	if manifest.GitCommitRegex.MatchString(entry.GitCommit) {
		commit, err := getGitCommit(entry.GitCommit)
		if err == nil {
			gitRepoCache[cacheKey] = commit
			entry.GitCommit = commit
			return commit, nil
		}
	}

	fetchString := entry.GitFetch + ":"
	if entry.GitFetch == manifest.DefaultLineBasedFetch {
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

	if strings.HasPrefix(entry.GitRepo, "git://github.com/") {
		fmt.Fprintf(os.Stderr, "warning: insecure protocol git:// detected: %s\n", entry.GitRepo)
		entry.GitRepo = strings.Replace(entry.GitRepo, "git://", "https://", 1)
	}

	_, err = git("fetch", "--quiet", "--no-tags", entry.GitRepo, fetchString)
	if err != nil {
		return "", err
	}

	commit, err := getGitCommit(entry.GitCommit)
	if err != nil {
		return "", err
	}

	_, err = git("tag", "--force", r.RepoName+"/"+entry.Tags[0], commit)
	if err != nil {
		return "", err
	}

	gitRepoCache[cacheKey] = commit
	entry.GitCommit = commit
	return commit, nil
}
