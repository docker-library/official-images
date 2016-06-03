package manifest

import (
	"bufio"
	"fmt"
	"io"
	"regexp"
	"strings"

	"github.com/docker-library/go-dockerlibrary/pkg/stripper"

	"pault.ag/go/debian/control"
)

var (
	GitCommitRegex = regexp.MustCompile(`^[0-9a-f]{1,40}$`)
	GitFetchRegex  = regexp.MustCompile(`^refs/(heads|tags)/[^*?:]+$`)
)

type Manifest2822 struct {
	Global  Manifest2822Entry
	Entries []Manifest2822Entry
}

type Manifest2822Entry struct {
	control.Paragraph

	Maintainers []string `delim:"," strip:"\n\r\t "`
	Tags        []string `delim:"," strip:"\n\r\t "`
	GitRepo     string
	GitFetch    string
	GitCommit   string
	Directory   string
	Constraints []string `delim:"," strip:"\n\r\t "`
}

var DefaultManifestEntry = Manifest2822Entry{
	GitFetch:  "refs/heads/master",
	Directory: ".",
}

func (entry Manifest2822Entry) Clone() Manifest2822Entry {
	// SLICES! grr
	entry.Maintainers = append([]string{}, entry.Maintainers...)
	entry.Tags = append([]string{}, entry.Tags...)
	entry.Constraints = append([]string{}, entry.Constraints...)
	return entry
}

const StringSeparator2822 = ", "

func (entry Manifest2822Entry) MaintainersString() string {
	return strings.Join(entry.Maintainers, StringSeparator2822)
}

func (entry Manifest2822Entry) TagsString() string {
	return strings.Join(entry.Tags, StringSeparator2822)
}

func (entry Manifest2822Entry) ConstraintsString() string {
	return strings.Join(entry.Constraints, StringSeparator2822)
}

// if this method returns "true", then a.Tags and b.Tags can safely be combined (for the purposes of building)
func (a Manifest2822Entry) SameBuildArtifacts(b Manifest2822Entry) bool {
	return a.GitRepo == b.GitRepo && a.GitFetch == b.GitFetch && a.GitCommit == b.GitCommit && a.Directory == b.Directory && a.ConstraintsString() == b.ConstraintsString()
}

// returns a new Entry with any of the values that are equal to the values in "defaults" cleared
func (entry Manifest2822Entry) ClearDefaults(defaults Manifest2822Entry) Manifest2822Entry {
	if entry.MaintainersString() == defaults.MaintainersString() {
		entry.Maintainers = nil
	}
	if entry.TagsString() == defaults.TagsString() {
		entry.Tags = nil
	}
	if entry.GitRepo == defaults.GitRepo {
		entry.GitRepo = ""
	}
	if entry.GitFetch == defaults.GitFetch {
		entry.GitFetch = ""
	}
	if entry.GitCommit == defaults.GitCommit {
		entry.GitCommit = ""
	}
	if entry.Directory == defaults.Directory {
		entry.Directory = ""
	}
	if entry.ConstraintsString() == defaults.ConstraintsString() {
		entry.Constraints = nil
	}
	return entry
}

func (entry Manifest2822Entry) String() string {
	ret := []string{}
	if str := entry.MaintainersString(); str != "" {
		ret = append(ret, "Maintainers: "+str)
	}
	if str := entry.TagsString(); str != "" {
		ret = append(ret, "Tags: "+str)
	}
	if str := entry.GitRepo; str != "" {
		ret = append(ret, "GitRepo: "+str)
	}
	if str := entry.GitFetch; str != "" {
		ret = append(ret, "GitFetch: "+str)
	}
	if str := entry.GitCommit; str != "" {
		ret = append(ret, "GitCommit: "+str)
	}
	if str := entry.Directory; str != "" {
		ret = append(ret, "Directory: "+str)
	}
	if str := entry.ConstraintsString(); str != "" {
		ret = append(ret, "Constraints: "+str)
	}
	return strings.Join(ret, "\n")
}

func (manifest Manifest2822) String() string {
	entries := []Manifest2822Entry{manifest.Global.ClearDefaults(DefaultManifestEntry)}
	entries = append(entries, manifest.Entries...)

	ret := []string{}
	for i, entry := range entries {
		if i > 0 {
			entry = entry.ClearDefaults(manifest.Global)
		}
		ret = append(ret, entry.String())
	}

	return strings.Join(ret, "\n\n")
}

func (entry Manifest2822Entry) HasTag(tag string) bool {
	for _, existingTag := range entry.Tags {
		if tag == existingTag {
			return true
		}
	}
	return false
}

func (manifest Manifest2822) GetTag(tag string) *Manifest2822Entry {
	for _, entry := range manifest.Entries {
		if entry.HasTag(tag) {
			return &entry
		}
	}
	return nil
}

func (manifest *Manifest2822) AddEntry(entry Manifest2822Entry) error {
	for _, tag := range entry.Tags {
		if manifest.GetTag(tag) != nil {
			return fmt.Errorf("Tags %q includes duplicate tag: %s", entry.TagsString(), tag)
		}
	}

	for i, existingEntry := range manifest.Entries {
		if existingEntry.SameBuildArtifacts(entry) {
			manifest.Entries[i].Tags = append(existingEntry.Tags, entry.Tags...)
			return nil
		}
	}

	manifest.Entries = append(manifest.Entries, entry)

	return nil
}

const (
	MaintainersNameRegex   = `[^\s<>()][^<>()]*`
	MaintainersEmailRegex  = `[^\s<>()]+`
	MaintainersGitHubRegex = `[^\s<>()]+`

	MaintainersFormat = `Full Name <contact-email-or-url> (@github-handle) OR Full Name (@github-handle)`
)

var (
	MaintainersRegex = regexp.MustCompile(`^(` + MaintainersNameRegex + `)(?:\s+<(` + MaintainersEmailRegex + `)>)?\s+[(]@(` + MaintainersGitHubRegex + `)[)]$`)
)

func (entry Manifest2822Entry) InvalidMaintainers() []string {
	invalid := []string{}
	for _, maintainer := range entry.Maintainers {
		if !MaintainersRegex.MatchString(maintainer) {
			invalid = append(invalid, maintainer)
		}
	}
	return invalid
}

type decoderWrapper struct {
	*control.Decoder
}

func (decoder *decoderWrapper) Decode(entry *Manifest2822Entry) error {
	for {
		err := decoder.Decoder.Decode(entry)
		if err != nil {
			return err
		}
		// ignore empty paragraphs (blank lines at the start, excess blank lines between paragraphs, excess blank lines at EOF)
		if len(entry.Paragraph.Order) > 0 {
			return nil
		}
	}
}

func Parse2822(readerIn io.Reader) (*Manifest2822, error) {
	reader := stripper.NewCommentStripper(readerIn)

	realDecoder, err := control.NewDecoder(bufio.NewReader(reader), nil)
	if err != nil {
		return nil, err
	}
	decoder := decoderWrapper{realDecoder}

	manifest := Manifest2822{
		Global: DefaultManifestEntry.Clone(),
	}

	if err := decoder.Decode(&manifest.Global); err != nil {
		return nil, err
	}
	if len(manifest.Global.Maintainers) < 1 {
		return nil, fmt.Errorf("missing Maintainers")
	}
	if invalidMaintainers := manifest.Global.InvalidMaintainers(); len(invalidMaintainers) > 0 {
		return nil, fmt.Errorf("invalid Maintainers: %q (expected format %q)", strings.Join(invalidMaintainers, ", "), MaintainersFormat)
	}
	if len(manifest.Global.Tags) > 0 {
		return nil, fmt.Errorf("global Tags not permitted")
	}

	for {
		entry := manifest.Global.Clone()

		err := decoder.Decode(&entry)
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		if len(entry.Tags) < 1 {
			return nil, fmt.Errorf("missing Tags")
		}
		if entry.GitRepo == "" || entry.GitFetch == "" || entry.GitCommit == "" {
			return nil, fmt.Errorf("Tags %q missing one of GitRepo, GitFetch, or GitCommit", entry.TagsString())
		}
		if !GitFetchRegex.MatchString(entry.GitFetch) {
			return nil, fmt.Errorf(`Tags %q has invalid GitFetch (must be "refs/heads/..." or "refs/tags/..."): %q`, entry.TagsString(), entry.GitFetch)
		}
		if !GitCommitRegex.MatchString(entry.GitCommit) {
			return nil, fmt.Errorf(`Tags %q has invalid GitCommit (must be a commit, not a tag or ref): %q`, entry.TagsString(), entry.GitCommit)
		}

		err = manifest.AddEntry(entry)
		if err != nil {
			return nil, err
		}
	}

	return &manifest, nil
}
