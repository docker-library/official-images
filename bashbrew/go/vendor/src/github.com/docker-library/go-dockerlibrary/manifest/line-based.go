package manifest

import (
	"bufio"
	"fmt"
	"io"
	"strings"
)

const DefaultLineBasedFetch = "refs/heads/*" // backwards compatibility

// TODO write more of a proper parser? (probably not worthwhile given that 2822 is the preferred format)
func ParseLineBasedLine(line string, defaults Manifest2822Entry) (*Manifest2822Entry, error) {
	entry := defaults.Clone()

	parts := strings.SplitN(line, ":", 2)
	if len(parts) < 2 {
		return nil, fmt.Errorf("manifest line missing ':': %s", line)
	}
	entry.Tags = []string{strings.TrimSpace(parts[0])}

	parts = strings.SplitN(parts[1], "@", 2)
	if len(parts) < 2 {
		return nil, fmt.Errorf("manifest line missing '@': %s", line)
	}
	entry.GitRepo = strings.TrimSpace(parts[0])

	parts = strings.SplitN(parts[1], " ", 2)
	entry.GitCommit = strings.TrimSpace(parts[0])
	if len(parts) > 1 {
		entry.Directory = strings.TrimSpace(parts[1])
	}

	if entry.GitFetch == DefaultLineBasedFetch && !GitCommitRegex.MatchString(entry.GitCommit) {
		// doesn't look like a commit, must be a tag
		entry.GitFetch = "refs/tags/" + entry.GitCommit
		entry.GitCommit = "FETCH_HEAD"
	}

	return &entry, nil
}

func ParseLineBased(readerIn io.Reader) (*Manifest2822, error) {
	reader := bufio.NewReader(readerIn)

	manifest := &Manifest2822{
		Global: DefaultManifestEntry.Clone(),
	}
	manifest.Global.GitFetch = DefaultLineBasedFetch

	for {
		line, err := reader.ReadString('\n')

		line = strings.TrimSpace(line)
		if len(line) > 0 {
			if line[0] == '#' {
				maintainerLine := strings.TrimPrefix(line, "# maintainer: ")
				if line != maintainerLine {
					// if the prefix was removed, it must be a maintainer line!
					manifest.Global.Maintainers = append(manifest.Global.Maintainers, maintainerLine)
				}
			} else {
				entry, parseErr := ParseLineBasedLine(line, manifest.Global)
				if parseErr != nil {
					return nil, parseErr
				}

				err = manifest.AddEntry(*entry)
				if err != nil {
					return nil, err
				}
			}
		}

		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
	}

	if len(manifest.Global.Maintainers) < 1 {
		return nil, fmt.Errorf("missing Maintainers")
	}
	if invalidMaintainers := manifest.Global.InvalidMaintainers(); len(invalidMaintainers) > 0 {
		return nil, fmt.Errorf("invalid Maintainers: %q (expected format %q)", strings.Join(invalidMaintainers, ", "), MaintainersFormat)
	}

	return manifest, nil
}
