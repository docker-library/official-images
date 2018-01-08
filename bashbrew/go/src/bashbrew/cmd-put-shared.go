package main

import (
	"fmt"
	"os"
	"path"
	"time"

	"github.com/codegangsta/cli"

	"github.com/docker-library/go-dockerlibrary/architecture"
	"github.com/docker-library/go-dockerlibrary/manifest"
)

func entriesToManifestToolYaml(singleArch bool, r Repo, entries ...*manifest.Manifest2822Entry) (string, time.Time, error) {
	yaml := ""
	mru := time.Time{}
	entryIdentifiers := []string{}
	for _, entry := range entries {
		entryIdentifiers = append(entryIdentifiers, r.EntryIdentifier(*entry))

		for _, entryArch := range entry.Architectures {
			if singleArch && entryArch != arch {
				continue
			}

			var ok bool

			var ociArch architecture.OCIPlatform
			if ociArch, ok = architecture.SupportedArches[entryArch]; !ok {
				// this should never happen -- the parser validates Architectures
				panic("somehow, an unsupported architecture slipped past the parser validation: " + entryArch)
			}

			var archNamespace string
			if archNamespace, ok = archNamespaces[entryArch]; !ok || archNamespace == "" {
				fmt.Fprintf(os.Stderr, "warning: no arch-namespace specified for %q; skipping (%q)\n", entryArch, r.EntryIdentifier(*entry))
				continue
			}

			archImage := fmt.Sprintf("%s/%s:%s", archNamespace, r.RepoName, entry.Tags[0])
			archImageMeta := fetchDockerHubTagMeta(archImage)
			if archU := archImageMeta.lastUpdatedTime(); archU.After(mru) {
				mru = archU
			}

			yaml += fmt.Sprintf("  - image: %s\n    platform:\n", archImage)
			yaml += fmt.Sprintf("      os: %s\n", ociArch.OS)
			yaml += fmt.Sprintf("      architecture: %s\n", ociArch.Architecture)
			if ociArch.Variant != "" {
				yaml += fmt.Sprintf("      variant: %s\n", ociArch.Variant)
			}
		}
	}

	return "manifests:\n" + yaml, mru, nil
}

func tagsToManifestToolYaml(repo string, tags ...string) string {
	yaml := fmt.Sprintf("image: %s:%s\n", repo, tags[0])
	if len(tags) > 1 {
		yaml += "tags:\n"
		for _, tag := range tags[1:] {
			yaml += fmt.Sprintf("  - %s\n", tag)
		}
	}
	return yaml
}

func cmdPutShared(c *cli.Context) error {
	repos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	namespace := c.String("namespace")
	dryRun := c.Bool("dry-run")
	singleArch := c.Bool("single-arch")

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "put-shared"`)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		targetRepo := path.Join(namespace, r.RepoName)

		sharedTagGroups := []manifest.SharedTagGroup{}

		if !singleArch {
			// handle all multi-architecture tags first (regardless of whether they have SharedTags)
			// turn them into SharedTagGroup objects so all manifest-tool invocations can be handled by a single process/loop
			for _, entry := range r.Entries() {
				entryCopy := entry
				sharedTagGroups = append(sharedTagGroups, manifest.SharedTagGroup{
					SharedTags: entry.Tags,
					Entries:    []*manifest.Manifest2822Entry{&entryCopy},
				})
			}
		}

		// TODO do something smarter with r.TagName (ie, the user has done something crazy like "bashbrew put-shared single-repo:single-tag")
		if r.TagName == "" {
			sharedTagGroups = append(sharedTagGroups, r.Manifest.GetSharedTagGroups()...)
		} else {
			fmt.Fprintf(os.Stderr, "warning: a single tag was requested -- skipping SharedTags\n")
		}

		if len(sharedTagGroups) == 0 {
			continue
		}

		for _, group := range sharedTagGroups {
			yaml, mostRecentPush, err := entriesToManifestToolYaml(singleArch, *r, group.Entries...)
			if err != nil {
				return err
			}

			tagsToPush := []string{}
			for _, tag := range group.SharedTags {
				image := fmt.Sprintf("%s:%s", targetRepo, tag)
				hubMeta := fetchDockerHubTagMeta(image)
				tagUpdated := hubMeta.lastUpdatedTime()
				if mostRecentPush.After(tagUpdated) ||
					(!singleArch && len(hubMeta.Images) <= 1 &&
						(len(group.Entries) > 1 || len(group.Entries[0].Architectures) > 1)) {
					tagsToPush = append(tagsToPush, tag)
				} else {
					fmt.Fprintf(os.Stderr, "skipping %s (created %s, last updated %s)\n", image, mostRecentPush.Local().Format(time.RFC3339), tagUpdated.Local().Format(time.RFC3339))
				}
			}

			if len(tagsToPush) == 0 {
				continue
			}

			groupIdentifier := fmt.Sprintf("%s:%s", targetRepo, tagsToPush[0])
			fmt.Printf("Putting %s\n", groupIdentifier)
			if !dryRun {
				tagYaml := tagsToManifestToolYaml(targetRepo, tagsToPush...) + yaml
				if err := manifestToolPushFromSpec(tagYaml); err != nil {
					return fmt.Errorf("failed pushing %s", groupIdentifier)
				}
			}
		}
	}

	return nil
}
