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

	goGit "gopkg.in/src-d/go-git.v4"
	goGitConfig "gopkg.in/src-d/go-git.v4/config"
	goGitPlumbing "gopkg.in/src-d/go-git.v4/plumbing"
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

var gitRepo *goGit.Repository

func ensureGitInit() error {
	if gitRepo != nil {
		return nil
	}

	gitCacheDir := gitCache()
	err := os.MkdirAll(gitCacheDir, os.ModePerm)
	if err != nil {
		return err
	}

	gitRepo, err = goGit.PlainInit(gitCacheDir, true)
	if err == goGit.ErrRepositoryAlreadyExists {
		gitRepo, err = goGit.PlainOpen(gitCacheDir)
	}
	if err != nil {
		return err
	}

	// ensure garbage collection is disabled so we keep dangling commits
	config, err := gitRepo.Config()
	if err != nil {
		return err
	}
	config.Raw = config.Raw.SetOption("gc", "", "auto", "0")
	gitRepo.Storer.SetConfig(config)

	return nil
}

var fullGitCommitRegex = regexp.MustCompile(`^[0-9a-f]{40}$|^[0-9a-f]{64}$`)

func getGitCommit(commit string) (string, error) {
	if fullGitCommitRegex.MatchString(commit) {
		_, err := gitRepo.CommitObject(goGitPlumbing.NewHash(commit))
		if err != nil {
			return "", err
		}
		return commit, nil
	}

	h, err := gitRepo.ResolveRevision(goGitPlumbing.Revision(commit + "^{commit}"))
	if err != nil {
		return "", err
	}
	return h.String(), nil
}

func gitStream(args ...string) (io.ReadCloser, error) {
	return execpipe.Run(gitCommand(args...))
}

func gitArchive(commit string, dir string) (io.ReadCloser, error) {
	if dir == "." {
		dir = ""
	} else {
		dir += "/"
	}
	return gitStream("archive", "--format=tar", commit+":"+dir)
}

func gitShow(commit string, file string) (string, error) {
	gitCommit, err := gitRepo.CommitObject(goGitPlumbing.NewHash(commit))
	if err != nil {
		return "", err
	}

	gitFile, err := gitCommit.File(file)
	if err != nil {
		return "", err
	}

	contents, err := gitFile.Contents()
	if err != nil {
		return "", err
	}

	return contents, nil
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
	} else {
		// we create a temporary remote dir so that we can clean it up completely afterwards
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
		if entry.ArchGitFetch(arch) == manifest.DefaultLineBasedFetch {
			// backwards compat (see manifest/line-based.go in go-dockerlibrary)
			fetchString += tempRef + "/*"
		} else {
			fetchString += tempRef + "/temp"
		}
	}

	if strings.HasPrefix(entry.ArchGitRepo(arch), "git://github.com/") {
		fmt.Fprintf(os.Stderr, "warning: insecure protocol git:// detected: %s\n", entry.ArchGitRepo(arch))
		entry.SetGitRepo(arch, strings.Replace(entry.ArchGitRepo(arch), "git://", "https://", 1))
	}

	gitRemote, err := gitRepo.CreateRemoteAnonymous(&goGitConfig.RemoteConfig{
		Name: "anonymous",
		URLs: []string{entry.ArchGitRepo(arch)},
	})
	if err != nil {
		return "", err
	}

	err = gitRemote.Fetch(&goGit.FetchOptions{
		RefSpecs: []goGitConfig.RefSpec{goGitConfig.RefSpec(fetchString)},
		Tags:     goGit.NoTags,

		//Progress: os.Stdout,
	})
	if err != nil {
		return "", err
	}

	commit, err := getGitCommit(entry.ArchGitCommit(arch))
	if err != nil {
		return "", err
	}

	gitTag := gitNormalizeForTagUsage(path.Join(arch, namespace, r.RepoName, entry.Tags[0]))
	gitRepo.DeleteTag(gitTag) // avoid "ErrTagExists"
	_, err = gitRepo.CreateTag(gitTag, goGitPlumbing.NewHash(commit), nil)
	if err != nil {
		return "", err
	}

	gitRepoCache[cacheKey] = commit
	entry.SetGitCommit(arch, commit)
	return commit, nil
}
