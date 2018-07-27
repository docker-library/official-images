package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

type tagMeta interface {
	lastUpdatedTime() time.Time
	imageCount() int
}

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

func (meta dockerHubTagMeta) imageCount() int {
	return len(meta.Images)
}

func fetchDockerHubTagMeta(repoTag string) dockerHubTagMeta {
	parts := strings.SplitN(repoTag, ":", 2)
	repo, tag := parts[0], parts[1]

	var meta dockerHubTagMeta

	resp, err := http.Get(fmt.Sprintf("https://hub.docker.com/v2/repositories/%s/tags/%s/", repo, tag))
	if err == nil {
		defer resp.Body.Close()

		json.NewDecoder(resp.Body).Decode(&meta)
	}
	return meta
}

type History struct {
	V1Compatibility string `json:"v1Compatibility"`
}

func (history History) lastUpdatedTime() time.Time {
	var compatibility map[string]interface{}
	err := json.Unmarshal([]byte(history.V1Compatibility), &compatibility)
	if err != nil {
		return time.Time{}
	}
	created := compatibility["created"].(string)
	t, err := time.Parse(time.RFC3339Nano, created)
	if err != nil {
		return time.Time{}
	}
	return t
}

type Manifest struct {
	History []History `json:"history"`
}

func (manifest Manifest) lastUpdatedTime() time.Time {
	var lastUpdatedTime time.Time
	for _, history := range manifest.History {
		updateTime := history.lastUpdatedTime()
		if updateTime.After(lastUpdatedTime) {
			lastUpdatedTime = updateTime
		}
	}
	return lastUpdatedTime
}

func (manifest Manifest) imageCount() int {
	return 1
}

func fetchRegistryManifest(registry, repoTag string) Manifest {
	var manifest Manifest
	registryURL, err := url.Parse(registry)
	if err != nil {
		return manifest
	}
	repoTag = repoTag[len(registryURL.Host)+1:]
	parts := strings.SplitN(repoTag, ":", 2)
	repo, tag := parts[0], parts[1]

	tagsURL := fmt.Sprintf("%s/v2/%s/manifests/%s", registry, repo, tag)
	if debugFlag {
		fmt.Printf("Fetching %s\n", tagsURL)
	}
	resp, err := http.Get(tagsURL)
	if err == nil {
		defer resp.Body.Close()

		err := json.NewDecoder(resp.Body).Decode(&manifest)
		if err != nil {
			panic(err)
		}
	}
	if debugFlag {
		fmt.Printf("Last updated %s\n", manifest.lastUpdatedTime())
	}
	return manifest
}

func fetchTagMeta(registry, repoTag string) tagMeta {
	repoTag = latestizeRepoTag(repoTag)
	if registry == dockerHub {
		return fetchDockerHubTagMeta(repoTag)
	}
	return fetchRegistryManifest(registry, repoTag)
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
