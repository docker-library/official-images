package main

import (
	"fmt"
	"os"
	"path"

	"github.com/codegangsta/cli"

	"github.com/docker-library/go-dockerlibrary/architecture"
	"github.com/docker-library/go-dockerlibrary/manifest"
)

func entriesToManifestToolYaml(r Repo, entries ...*manifest.Manifest2822Entry) (string, error) {
	yaml := ""
	entryIdentifiers := []string{}
	for _, entry := range entries {
		entryIdentifiers = append(entryIdentifiers, r.EntryIdentifier(*entry))

		for _, arch := range entry.Architectures {
			var ok bool

			var ociArch architecture.OCIPlatform
			if ociArch, ok = architecture.SupportedArches[arch]; !ok {
				// this should never happen -- the parser validates Architectures
				panic("somehow, an unsupported architecture slipped past the parser validation: " + arch)
			}

			var archNamespace string
			if archNamespace, ok = archNamespaces[arch]; !ok || archNamespace == "" {
				fmt.Fprintf(os.Stderr, "warning: no arch-namespace specified for %q; skipping (%q)\n", arch, r.EntryIdentifier(*entry))
				continue
			}

			yaml += fmt.Sprintf("  - image: %s/%s:%s\n    platform:\n", archNamespace, r.RepoName, entry.Tags[0])
			yaml += fmt.Sprintf("      os: %s\n", ociArch.OS)
			yaml += fmt.Sprintf("      architecture: %s\n", ociArch.Architecture)
			if ociArch.Variant != "" {
				yaml += fmt.Sprintf("      variant: %s\n", ociArch.Variant)
			}
		}
	}
	if yaml == "" {
		return "", fmt.Errorf("failed gathering images for creating %q", entryIdentifiers)
	}

	return "manifests:\n" + yaml, nil
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

	if namespace == "" {
		return fmt.Errorf(`"--namespace" is a required flag for "put-shared"`)
	}

	for _, repo := range repos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		targetRepo := path.Join(namespace, r.RepoName)

		// handle all multi-architecture tags first (regardless of whether they have SharedTags)
		for _, entry := range r.Entries() {
			// "image:" will be added later so we don't have to regenerate the entire "manifests" section every time
			yaml, err := entriesToManifestToolYaml(*r, &entry)
			if err != nil {
				return err
			}

			entryIdentifier := fmt.Sprintf("%s:%s", targetRepo, entry.Tags[0])
			fmt.Printf("Putting %s\n", entryIdentifier)
			tagYaml := tagsToManifestToolYaml(targetRepo, entry.Tags...) + yaml
			if err := manifestToolPushFromSpec(tagYaml); err != nil {
				return fmt.Errorf("failed pushing %q (%q)", entryIdentifier, entry.TagsString())
			}
		}

		// TODO do something better with r.TagName (ie, the user has done something crazy like "bashbrew put-shared single-repo:single-tag")
		sharedTagGroups := r.Manifest.GetSharedTagGroups()
		if len(sharedTagGroups) == 0 {
			continue
		}
		if r.TagName != "" {
			fmt.Fprintf(os.Stderr, "warning: a single tag was requested -- skipping SharedTags\n")
			continue
		}

		for _, group := range sharedTagGroups {
			yaml, err := entriesToManifestToolYaml(*r, group.Entries...)
			if err != nil {
				return err
			}

			groupIdentifier := fmt.Sprintf("%s:%s", targetRepo, group.SharedTags[0])
			fmt.Printf("Putting shared %s\n", groupIdentifier)
			tagYaml := tagsToManifestToolYaml(targetRepo, group.SharedTags...) + yaml
			if err := manifestToolPushFromSpec(tagYaml); err != nil {
				return fmt.Errorf("failed pushing %s", groupIdentifier)
			}
		}
	}

	return nil
}
