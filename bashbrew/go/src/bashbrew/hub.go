package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

type dockerHubTagMeta struct {
	// we don't care what's in these -- we just need to be able to count them
	Images []interface{} `json:"images"`

	LastUpdated string `json:"last_updated"`
}

func (meta dockerHubTagMeta) lastUpdatedTime() time.Time {
	t, err := time.Parse(time.RFC3339Nano, meta.LastUpdated)
	if err != nil {
		return time.Time{}
	}
	return t
}

func fetchDockerHubTagMeta(repoTag string) dockerHubTagMeta {
	repoTag = latestizeRepoTag(repoTag)
	parts := strings.SplitN(repoTag, ":", 2)
	repo, tag := parts[0], parts[1]

	var meta dockerHubTagMeta

	resp, err := http.Get(fmt.Sprintf("https://hub.docker.com/v2/repositories/%s/tags/%s/", repo, tag))
	if err != nil {
		return meta
	}
	defer resp.Body.Close()

	err = json.NewDecoder(resp.Body).Decode(&meta)
	if err != nil {
		return meta
	}

	return meta
}

func dockerCreated(image string) time.Time {
	created, err := dockerInspect("{{.Created}}", image)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: error while fetching creation time of %q: %v\n", image, err)
		return time.Now()
	}
	created = strings.TrimSpace(created)

	t, err := time.Parse(time.RFC3339Nano, created)
	if err != nil {
		fmt.Fprintf(os.Stderr, "warning: error while parsing creation time of %q (%q): %v\n", image, created, err)
		return time.Now()
	}

	return t
}
