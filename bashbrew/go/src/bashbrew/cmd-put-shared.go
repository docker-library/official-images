package main

import (
	"fmt"
	"os"
	"path"
	"strings"
	"time"

	"github.com/codegangsta/cli"

	"github.com/docker-library/go-dockerlibrary/architecture"
	"github.com/docker-library/go-dockerlibrary/manifest"
)

func entriesToManifestToolYaml(singleArch bool, r Repo, entries ...*manifest.Manifest2822Entry) (string, time.Time, int, error) {
	yaml := ""
	mru := time.Time{}
	expectedNumber := 0
	entryIdentifiers := []string{}
	for _, entry := range entries {
		entryIdentifiers = append(entryIdentifiers, r.EntryIdentifier(entry))

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
				fmt.Fprintf(os.Stderr, "warning: no arch-namespace specified for %q; skipping (%q)\n", entryArch, r.EntryIdentifier(entry))
				continue
			}

			archImage := fmt.Sprintf("%s/%s:%s", archNamespace, r.RepoName, entry.Tags[0])
			archImageMeta := fetchDockerHubTagMeta(archImage)
			if archU := archImageMeta.lastUpdatedTime(); archU.After(mru) {
				mru = archU
			}

			// count up how many images we expect to push successfully in this manifest list
			expectedNumber += len(archImageMeta.Images)
			// for non-manifest-list tags, this will be 1 and for failed lookups it'll be 0
			// (and if one of _these_ tags is a manifest list, we've goofed somewhere)
			if len(archImageMeta.Images) != 1 {
				fmt.Fprintf(os.Stderr, "warning: expected 1 image for %q; got %d\n", archImage, len(archImageMeta.Images))
			}

			yaml += fmt.Sprintf("  - image: %s\n    platform:\n", archImage)
			yaml += fmt.Sprintf("      os: %s\n", ociArch.OS)
			yaml += fmt.Sprintf("      architecture: %s\n", ociArch.Architecture)
			if ociArch.Variant != "" {
				yaml += fmt.Sprintf("      variant: %s\n", ociArch.Variant)
			}
		}
	}

	return "manifests:\n" + yaml, mru, expectedNumber, nil
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

	dryRun := c.Bool("dry-run")
	targetNamespace := c.String("target-namespace")
	force := c.Bool("force")
	singleArch := c.Bool("single-arch")

	if targetNamespace == "" {
		targetNamespace = namespace
	}
	if targetNamespace == "" {
		return fmt.Errorf(`either "--target-namespace" or "--namespace" is a required flag for "put-shared"`)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		targetRepo := path.Join(targetNamespace, r.RepoName)

		sharedTagGroups := []manifest.SharedTagGroup{}

		if !singleArch {
			// handle all multi-architecture tags first (regardless of whether they have SharedTags)
			// turn them into SharedTagGroup objects so all manifest-tool invocations can be handled by a single process/loop
			for _, entry := range r.Entries() {
				entryCopy := *entry
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

		failed := []string{}
		for _, group := range sharedTagGroups {
			yaml, mostRecentPush, expectedNumber, err := entriesToManifestToolYaml(singleArch, *r, group.Entries...)
			if err != nil {
				return err
			}

			if expectedNumber < 1 {
				// if "expectedNumber" comes back as 0, we've probably got an API issue, so let's count up what we probably _should_ push
				fmt.Fprintf(os.Stderr, "warning: no images expected to push for %q\n", fmt.Sprintf("%s:%s", targetRepo, group.SharedTags[0]))
				for _, entry := range group.Entries {
					expectedNumber += len(entry.Architectures)
				}
			}

			tagsToPush := []string{}
			for _, tag := range group.SharedTags {
				image := fmt.Sprintf("%s:%s", targetRepo, tag)
				if !force {
					hubMeta := fetchDockerHubTagMeta(image)
					tagUpdated := hubMeta.lastUpdatedTime()
					doPush := false
					if mostRecentPush.After(tagUpdated) {
						// if one of the images that make up the manifest list has been updated since the manifest list was last pushed, we probably need to push
						doPush = true
					}
					if !singleArch && len(hubMeta.Images) != expectedNumber {
						// if we're supposed to push more (or less) images than the current manifest list contains, we probably need to push
						// this _should_ already be accounting for tags that haven't been pushed yet (see notes above in "entriesToManifestToolYaml" where this is calculated)
						doPush = true
					}
					if !doPush {
						fmt.Fprintf(os.Stderr, "skipping %s (created %s, last updated %s)\n", image, mostRecentPush.Local().Format(time.RFC3339), tagUpdated.Local().Format(time.RFC3339))
						continue
					}
				}
				tagsToPush = append(tagsToPush, tag)
			}

			if len(tagsToPush) == 0 {
				continue
			}

			groupIdentifier := fmt.Sprintf("%s:%s", targetRepo, tagsToPush[0])
			fmt.Printf("Putting %s\n", groupIdentifier)
			if !dryRun {
				tagYaml := tagsToManifestToolYaml(targetRepo, tagsToPush...) + yaml
				if err := manifestToolPushFromSpec(tagYaml); err != nil {
					fmt.Fprintf(os.Stderr, "warning: failed putting %s, skipping (collecting errors)\n", groupIdentifier)
					failed = append(failed, fmt.Sprintf("- %s: %v", groupIdentifier, err))
					continue
				}
			}
		}
		if len(failed) > 0 {
			return fmt.Errorf("failed putting groups:\n%s", strings.Join(failed, "\n"))
		}
	}

	return nil
}
