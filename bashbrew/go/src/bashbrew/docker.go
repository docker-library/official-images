package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/docker-library/go-dockerlibrary/manifest"
)

var dockerFromCache = map[string]string{}

func (r Repo) DockerFrom(entry *manifest.Manifest2822Entry) (string, error) {
	return r.ArchDockerFrom(arch, entry)
}

func (r Repo) ArchDockerFrom(arch string, entry *manifest.Manifest2822Entry) (string, error) {
	commit, err := r.fetchGitRepo(arch, entry)
	if err != nil {
		return "", err
	}

	dockerfileFile := path.Join(entry.ArchDirectory(arch), "Dockerfile")

	cacheKey := strings.Join([]string{
		commit,
		dockerfileFile,
	}, "\n")
	if from, ok := dockerFromCache[cacheKey]; ok {
		return from, nil
	}

	dockerfile, err := gitShow(commit, dockerfileFile)
	if err != nil {
		return "", err
	}
	defer dockerfile.Close()

	from, err := dockerfileFrom(dockerfile)
	if err != nil {
		return "", err
	}

	if err := dockerfile.Close(); err != nil {
		return "", err
	}

	// make sure to add ":latest" if it's implied
	from = latestizeRepoTag(from)

	dockerFromCache[cacheKey] = from
	return from, nil
}

// TODO determine multi-stage-builds impact here (once official images are willing/able to support them; post-17.06 at the earliest)
func dockerfileFrom(dockerfile io.Reader) (string, error) {
	scanner := bufio.NewScanner(dockerfile)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			// ignore blank lines
			continue
		}
		if line[0] == '#' {
			// ignore comments
			continue
		}
		fields := strings.Fields(line)
		if len(fields) < 1 {
			continue
		}
		if strings.ToUpper(fields[0]) == "FROM" {
			return fields[1], nil
		}
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}
	return "", nil
}

func (r Repo) DockerCacheName(entry *manifest.Manifest2822Entry) (string, error) {
	cacheHash, err := r.dockerCacheHash(entry)
	if err != nil {
		return "", err
	}
	return "bashbrew/cache:" + cacheHash, err
}

func (r Repo) dockerCacheHash(entry *manifest.Manifest2822Entry) (string, error) {
	uniqueBits, err := r.dockerBuildUniqueBits(entry)
	if err != nil {
		return "", err
	}
	uniqueString := strings.Join(uniqueBits, "\n")
	b := sha256.Sum256([]byte(uniqueString))
	return hex.EncodeToString(b[:]), nil
}

func dockerInspect(format string, args ...string) (string, error) {
	args = append([]string{"inspect", "-f", format}, args...)
	out, err := exec.Command("docker", args...).Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return "", fmt.Errorf("%v\ncommand: docker inspect -f %q %q\n%s", ee, format, args, string(ee.Stderr))
		}
	}
	return string(out), nil
}

var dockerFromIdCache = map[string]string{
	"scratch": "scratch",
}

func (r Repo) dockerBuildUniqueBits(entry *manifest.Manifest2822Entry) ([]string, error) {
	from, err := r.DockerFrom(entry)
	if err != nil {
		return nil, err
	}
	fromId, ok := dockerFromIdCache[from]
	if !ok {
		var err error
		fromId, err = dockerInspect("{{.Id}}", from)
		if err != nil {
			return nil, err
		}
		dockerFromIdCache[from] = fromId
	}
	return []string{
		entry.ArchGitRepo(arch),
		entry.ArchGitCommit(arch),
		entry.ArchDirectory(arch),
		fromId,
	}, nil
}

func dockerBuild(tag string, context io.Reader) error {
	args := []string{"build", "-t", tag, "--rm", "--force-rm"}
	args = append(args, "-")
	cmd := exec.Command("docker", args...)
	cmd.Stdin = context
	if debugFlag {
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		fmt.Printf("$ docker %q\n", args)
		return cmd.Run()
	} else {
		buf := &bytes.Buffer{}
		cmd.Stdout = buf
		cmd.Stderr = buf
		err := cmd.Run()
		if err != nil {
			err = cli.NewMultiError(err, fmt.Errorf(`docker %q output:%s`, args, "\n"+buf.String()))
		}
		return err
	}
}

func dockerTag(tag1 string, tag2 string) error {
	if debugFlag {
		fmt.Printf("$ docker tag %q %q\n", tag1, tag2)
	}
	_, err := exec.Command("docker", "tag", tag1, tag2).Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("%v\ncommand: docker tag %q %q\n%s", ee, tag1, tag2, string(ee.Stderr))
		}
	}
	return err
}

func dockerPush(tag string) error {
	if debugFlag {
		fmt.Printf("$ docker push %q\n", tag)
	}
	_, err := exec.Command("docker", "push", tag).Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("%v\ncommand: docker push %q\n%s", ee, tag, string(ee.Stderr))
		}
	}
	return err
}

func dockerPull(tag string) error {
	if debugFlag {
		fmt.Printf("$ docker pull %q\n", tag)
	}
	_, err := exec.Command("docker", "pull", tag).Output()
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("%v\ncommand: docker pull %q\n%s", ee, tag, string(ee.Stderr))
		}
	}
	return err
}
