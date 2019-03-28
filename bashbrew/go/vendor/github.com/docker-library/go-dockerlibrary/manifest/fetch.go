package manifest

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
)

func validateTagName(man *Manifest2822, repoName, tagName string) error {
	if tagName != "" && (man.GetTag(tagName) == nil && len(man.GetSharedTag(tagName)) == 0) {
		return fmt.Errorf("tag not found in manifest for %q: %q", repoName, tagName)
	}
	return nil
}

// "library" is the default "library directory"
// returns the parsed version of (in order):
//   if "repo" is a URL, the remote contents of that URL
//   if "repo" is a relative path like "./repo", that file
//   the file "library/repo"
// (repoName, tagName, man, err)
func Fetch(library, repo string) (string, string, *Manifest2822, error) {
	repoName := filepath.Base(repo)
	tagName := ""
	if tagIndex := strings.IndexRune(repoName, ':'); tagIndex > 0 {
		tagName = repoName[tagIndex+1:]
		repoName = repoName[:tagIndex]
		repo = strings.TrimSuffix(repo, ":"+tagName)
	}

	u, err := url.Parse(repo)
	if err == nil && u.IsAbs() && (u.Scheme == "http" || u.Scheme == "https") {
		// must be remote URL!
		resp, err := http.Get(repo)
		if err != nil {
			return repoName, tagName, nil, err
		}
		defer resp.Body.Close()
		man, err := Parse(resp.Body)
		if err != nil {
			return repoName, tagName, man, err
		}
		return repoName, tagName, man, validateTagName(man, repoName, tagName)
	}

	// try file paths
	filePaths := []string{}
	if filepath.IsAbs(repo) || strings.IndexRune(repo, filepath.Separator) >= 0 || strings.IndexRune(repo, '/') >= 0 {
		filePaths = append(filePaths, repo)
	}
	if !filepath.IsAbs(repo) {
		filePaths = append(filePaths, filepath.Join(library, repo))
	}
	for _, fileName := range filePaths {
		f, err := os.Open(fileName)
		if err != nil && !os.IsNotExist(err) {
			return repoName, tagName, nil, err
		}
		if err == nil {
			defer f.Close()
			man, err := Parse(f)
			if err != nil {
				return repoName, tagName, man, err
			}
			return repoName, tagName, man, validateTagName(man, repoName, tagName)
		}
	}

	return repoName, tagName, nil, fmt.Errorf("unable to find a manifest named %q (in %q or as a remote URL)", repo, library)
}
