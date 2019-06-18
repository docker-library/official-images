package manifest

import (
	"bufio"
	"fmt"
	"io"
	"path"
	"regexp"
	"sort"
	"strings"

	"github.com/docker-library/go-dockerlibrary/architecture"
	"github.com/docker-library/go-dockerlibrary/pkg/stripper"

	"pault.ag/go/debian/control"
)

var (
	GitCommitRegex = regexp.MustCompile(`^[0-9a-f]{1,64}$`)
	GitFetchRegex  = regexp.MustCompile(`^refs/(heads|tags)/[^*?:]+$`)
)

type Manifest2822 struct {
	Global  Manifest2822Entry
	Entries []Manifest2822Entry
}

type Manifest2822Entry struct {
	control.Paragraph

	Maintainers []string `delim:"," strip:"\n\r\t "`

	Tags       []string `delim:"," strip:"\n\r\t "`
	SharedTags []string `delim:"," strip:"\n\r\t "`

	Architectures []string `delim:"," strip:"\n\r\t "`

	GitRepo   string
	GitFetch  string
	GitCommit string
	Directory string
	File      string

	// architecture-specific versions of the above fields
	ArchValues map[string]string
	// "ARCH-FIELD: VALUE"
	// ala, "s390x-GitCommit: deadbeef"
	// (sourced from Paragraph.Values via .SeedArchValues())

	Constraints []string `delim:"," strip:"\n\r\t "`
}

var (
	DefaultArchitecture = "amd64"

	DefaultManifestEntry = Manifest2822Entry{
		Architectures: []string{DefaultArchitecture},

		GitFetch:  "refs/heads/master",
		Directory: ".",
		File:      "Dockerfile",
	}
)

func deepCopyStringsMap(a map[string]string) map[string]string {
	b := map[string]string{}
	for k, v := range a {
		b[k] = v
	}
	return b
}

func (entry Manifest2822Entry) Clone() Manifest2822Entry {
	// SLICES! grr
	entry.Maintainers = append([]string{}, entry.Maintainers...)
	entry.Tags = append([]string{}, entry.Tags...)
	entry.SharedTags = append([]string{}, entry.SharedTags...)
	entry.Architectures = append([]string{}, entry.Architectures...)
	entry.Constraints = append([]string{}, entry.Constraints...)
	// and MAPS, oh my
	entry.ArchValues = deepCopyStringsMap(entry.ArchValues)
	return entry
}

func (entry *Manifest2822Entry) SeedArchValues() {
	for field, val := range entry.Paragraph.Values {
		if strings.HasSuffix(field, "-GitRepo") || strings.HasSuffix(field, "-GitFetch") || strings.HasSuffix(field, "-GitCommit") || strings.HasSuffix(field, "-Directory") || strings.HasSuffix(field, "-File") {
			entry.ArchValues[field] = val
		}
	}
}
func (entry *Manifest2822Entry) CleanDirectoryValues() {
	entry.Directory = path.Clean(entry.Directory)
	for field, val := range entry.ArchValues {
		if strings.HasSuffix(field, "-Directory") && val != "" {
			entry.ArchValues[field] = path.Clean(val)
		}
	}
}

const StringSeparator2822 = ", "

func (entry Manifest2822Entry) MaintainersString() string {
	return strings.Join(entry.Maintainers, StringSeparator2822)
}

func (entry Manifest2822Entry) TagsString() string {
	return strings.Join(entry.Tags, StringSeparator2822)
}

func (entry Manifest2822Entry) SharedTagsString() string {
	return strings.Join(entry.SharedTags, StringSeparator2822)
}

func (entry Manifest2822Entry) ArchitecturesString() string {
	return strings.Join(entry.Architectures, StringSeparator2822)
}

func (entry Manifest2822Entry) ConstraintsString() string {
	return strings.Join(entry.Constraints, StringSeparator2822)
}

// if this method returns "true", then a.Tags and b.Tags can safely be combined (for the purposes of building)
func (a Manifest2822Entry) SameBuildArtifacts(b Manifest2822Entry) bool {
	// check xxxarch-GitRepo, etc. fields for sameness first
	for _, key := range append(a.archFields(), b.archFields()...) {
		if a.ArchValues[key] != b.ArchValues[key] {
			return false
		}
	}

	return a.ArchitecturesString() == b.ArchitecturesString() && a.GitRepo == b.GitRepo && a.GitFetch == b.GitFetch && a.GitCommit == b.GitCommit && a.Directory == b.Directory && a.File == b.File && a.ConstraintsString() == b.ConstraintsString()
}

// returns a list of architecture-specific fields in an Entry
func (entry Manifest2822Entry) archFields() []string {
	ret := []string{}
	for key, val := range entry.ArchValues {
		if val != "" {
			ret = append(ret, key)
		}
	}
	sort.Strings(ret)
	return ret
}

// returns a new Entry with any of the values that are equal to the values in "defaults" cleared
func (entry Manifest2822Entry) ClearDefaults(defaults Manifest2822Entry) Manifest2822Entry {
	entry = entry.Clone() // make absolutely certain we have a deep clone
	if entry.MaintainersString() == defaults.MaintainersString() {
		entry.Maintainers = nil
	}
	if entry.TagsString() == defaults.TagsString() {
		entry.Tags = nil
	}
	if entry.SharedTagsString() == defaults.SharedTagsString() {
		entry.SharedTags = nil
	}
	if entry.ArchitecturesString() == defaults.ArchitecturesString() {
		entry.Architectures = nil
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
	if entry.File == defaults.File {
		entry.File = ""
	}
	for _, key := range defaults.archFields() {
		if defaults.ArchValues[key] == entry.ArchValues[key] {
			delete(entry.ArchValues, key)
		}
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
	if str := entry.SharedTagsString(); str != "" {
		ret = append(ret, "SharedTags: "+str)
	}
	if str := entry.ArchitecturesString(); str != "" {
		ret = append(ret, "Architectures: "+str)
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
	if str := entry.File; str != "" {
		ret = append(ret, "File: "+str)
	}
	for _, key := range entry.archFields() {
		ret = append(ret, key+": "+entry.ArchValues[key])
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

func (entry *Manifest2822Entry) SetGitRepo(arch string, repo string) {
	if entry.ArchValues == nil {
		entry.ArchValues = map[string]string{}
	}
	entry.ArchValues[arch+"-GitRepo"] = repo
}

func (entry Manifest2822Entry) ArchGitRepo(arch string) string {
	if val, ok := entry.ArchValues[arch+"-GitRepo"]; ok && val != "" {
		return val
	}
	return entry.GitRepo
}

func (entry Manifest2822Entry) ArchGitFetch(arch string) string {
	if val, ok := entry.ArchValues[arch+"-GitFetch"]; ok && val != "" {
		return val
	}
	return entry.GitFetch
}

func (entry *Manifest2822Entry) SetGitCommit(arch string, commit string) {
	if entry.ArchValues == nil {
		entry.ArchValues = map[string]string{}
	}
	entry.ArchValues[arch+"-GitCommit"] = commit
}

func (entry Manifest2822Entry) ArchGitCommit(arch string) string {
	if val, ok := entry.ArchValues[arch+"-GitCommit"]; ok && val != "" {
		return val
	}
	return entry.GitCommit
}

func (entry Manifest2822Entry) ArchDirectory(arch string) string {
	if val, ok := entry.ArchValues[arch+"-Directory"]; ok && val != "" {
		return val
	}
	return entry.Directory
}

func (entry Manifest2822Entry) ArchFile(arch string) string {
	if val, ok := entry.ArchValues[arch+"-File"]; ok && val != "" {
		return val
	}
	return entry.File
}

func (entry Manifest2822Entry) HasTag(tag string) bool {
	for _, existingTag := range entry.Tags {
		if tag == existingTag {
			return true
		}
	}
	return false
}

// HasSharedTag returns true if the given tag exists in entry.SharedTags.
func (entry Manifest2822Entry) HasSharedTag(tag string) bool {
	for _, existingTag := range entry.SharedTags {
		if tag == existingTag {
			return true
		}
	}
	return false
}

// HasArchitecture returns true if the given architecture exists in entry.Architectures
func (entry Manifest2822Entry) HasArchitecture(arch string) bool {
	for _, existingArch := range entry.Architectures {
		if arch == existingArch {
			return true
		}
	}
	return false
}

func (manifest Manifest2822) GetTag(tag string) *Manifest2822Entry {
	for i, entry := range manifest.Entries {
		if entry.HasTag(tag) {
			return &manifest.Entries[i]
		}
	}
	return nil
}

// GetSharedTag returns a list of entries with the given tag in entry.SharedTags (or the empty list if there are no entries with the given tag).
func (manifest Manifest2822) GetSharedTag(tag string) []*Manifest2822Entry {
	ret := []*Manifest2822Entry{}
	for i, entry := range manifest.Entries {
		if entry.HasSharedTag(tag) {
			ret = append(ret, &manifest.Entries[i])
		}
	}
	return ret
}

// GetAllSharedTags returns a list of the sum of all SharedTags in all entries of this image manifest (in the order they appear in the file).
func (manifest Manifest2822) GetAllSharedTags() []string {
	fakeEntry := Manifest2822Entry{}
	for _, entry := range manifest.Entries {
		fakeEntry.SharedTags = append(fakeEntry.SharedTags, entry.SharedTags...)
	}
	fakeEntry.DeduplicateSharedTags()
	return fakeEntry.SharedTags
}

type SharedTagGroup struct {
	SharedTags []string
	Entries    []*Manifest2822Entry
}

// GetSharedTagGroups returns a map of shared tag groups to the list of entries they share (as described in https://github.com/docker-library/go-dockerlibrary/pull/2#issuecomment-277853597).
func (manifest Manifest2822) GetSharedTagGroups() []SharedTagGroup {
	inter := map[string][]string{}
	interOrder := []string{} // order matters, and maps randomize order
	interKeySep := ","
	for _, sharedTag := range manifest.GetAllSharedTags() {
		interKeyParts := []string{}
		for _, entry := range manifest.GetSharedTag(sharedTag) {
			interKeyParts = append(interKeyParts, entry.Tags[0])
		}
		interKey := strings.Join(interKeyParts, interKeySep)
		if _, ok := inter[interKey]; !ok {
			interOrder = append(interOrder, interKey)
		}
		inter[interKey] = append(inter[interKey], sharedTag)
	}
	ret := []SharedTagGroup{}
	for _, tags := range interOrder {
		group := SharedTagGroup{
			SharedTags: inter[tags],
			Entries:    []*Manifest2822Entry{},
		}
		for _, tag := range strings.Split(tags, interKeySep) {
			group.Entries = append(group.Entries, manifest.GetTag(tag))
		}
		ret = append(ret, group)
	}
	return ret
}

func (manifest *Manifest2822) AddEntry(entry Manifest2822Entry) error {
	if len(entry.Tags) < 1 {
		return fmt.Errorf("missing Tags")
	}
	if entry.GitRepo == "" || entry.GitFetch == "" || entry.GitCommit == "" {
		return fmt.Errorf("Tags %q missing one of GitRepo, GitFetch, or GitCommit", entry.TagsString())
	}
	if invalidMaintainers := entry.InvalidMaintainers(); len(invalidMaintainers) > 0 {
		return fmt.Errorf("Tags %q has invalid Maintainers: %q (expected format %q)", entry.TagsString(), strings.Join(invalidMaintainers, ", "), MaintainersFormat)
	}

	entry.DeduplicateSharedTags()
	entry.CleanDirectoryValues()

	if invalidArchitectures := entry.InvalidArchitectures(); len(invalidArchitectures) > 0 {
		return fmt.Errorf("Tags %q has invalid Architectures: %q", entry.TagsString(), strings.Join(invalidArchitectures, ", "))
	}

	seenTag := map[string]bool{}
	for _, tag := range entry.Tags {
		if otherEntry := manifest.GetTag(tag); otherEntry != nil {
			return fmt.Errorf("Tags %q includes duplicate tag: %q (duplicated in %q)", entry.TagsString(), tag, otherEntry.TagsString())
		}
		if otherEntries := manifest.GetSharedTag(tag); len(otherEntries) > 0 {
			return fmt.Errorf("Tags %q includes tag conflicting with a shared tag: %q (shared tag in %q)", entry.TagsString(), tag, otherEntries[0].TagsString())
		}
		if seenTag[tag] {
			return fmt.Errorf("Tags %q includes duplicate tag: %q", entry.TagsString(), tag)
		}
		seenTag[tag] = true
	}
	for _, tag := range entry.SharedTags {
		if otherEntry := manifest.GetTag(tag); otherEntry != nil {
			return fmt.Errorf("Tags %q includes conflicting shared tag: %q (duplicated in %q)", entry.TagsString(), tag, otherEntry.TagsString())
		}
		if seenTag[tag] {
			return fmt.Errorf("Tags %q includes duplicate tag: %q (in SharedTags)", entry.TagsString(), tag)
		}
		seenTag[tag] = true
	}

	for i, existingEntry := range manifest.Entries {
		if existingEntry.SameBuildArtifacts(entry) {
			manifest.Entries[i].Tags = append(existingEntry.Tags, entry.Tags...)
			manifest.Entries[i].SharedTags = append(existingEntry.SharedTags, entry.SharedTags...)
			manifest.Entries[i].DeduplicateSharedTags()
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

func (entry Manifest2822Entry) InvalidArchitectures() []string {
	invalid := []string{}
	for _, arch := range entry.Architectures {
		if _, ok := architecture.SupportedArches[arch]; !ok {
			invalid = append(invalid, arch)
		}
	}
	return invalid
}

// DeduplicateSharedTags will remove duplicate values from entry.SharedTags, preserving order.
func (entry *Manifest2822Entry) DeduplicateSharedTags() {
	aggregate := []string{}
	seen := map[string]bool{}
	for _, tag := range entry.SharedTags {
		if seen[tag] {
			continue
		}
		seen[tag] = true
		aggregate = append(aggregate, tag)
	}
	entry.SharedTags = aggregate
}

// DeduplicateArchitectures will remove duplicate values from entry.Architectures and sort the result.
func (entry *Manifest2822Entry) DeduplicateArchitectures() {
	aggregate := []string{}
	seen := map[string]bool{}
	for _, arch := range entry.Architectures {
		if seen[arch] {
			continue
		}
		seen[arch] = true
		aggregate = append(aggregate, arch)
	}
	sort.Strings(aggregate)
	entry.Architectures = aggregate
}

type decoderWrapper struct {
	*control.Decoder
}

func (decoder *decoderWrapper) Decode(entry *Manifest2822Entry) error {
	// reset Architectures and SharedTags so that they can be either inherited or replaced, not additive
	sharedTags := entry.SharedTags
	entry.SharedTags = nil
	arches := entry.Architectures
	entry.Architectures = nil

	for {
		err := decoder.Decoder.Decode(entry)
		if err != nil {
			return err
		}

		// ignore empty paragraphs (blank lines at the start, excess blank lines between paragraphs, excess blank lines at EOF)
		if len(entry.Paragraph.Order) == 0 {
			continue
		}

		// if we had no SharedTags or Architectures, restore our "default" (original) values
		if len(entry.SharedTags) == 0 {
			entry.SharedTags = sharedTags
		}
		if len(entry.Architectures) == 0 {
			entry.Architectures = arches
		}
		entry.DeduplicateArchitectures()

		// pull out any new architecture-specific values from Paragraph.Values
		entry.SeedArchValues()

		return nil
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
	if invalidArchitectures := manifest.Global.InvalidArchitectures(); len(invalidArchitectures) > 0 {
		return nil, fmt.Errorf("invalid global Architectures: %q", strings.Join(invalidArchitectures, ", "))
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
