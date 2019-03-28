/* {{{ Copyright (c) Paul R. Tagliamonte <paultag@debian.org>, 2015
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE. }}} */

package control // import "pault.ag/go/debian/control"

import (
	"bufio"
	"strings"

	"pault.ag/go/debian/dependency"
	"pault.ag/go/debian/version"
)

// The BinaryIndex struct represents the exported APT Binary package index
// file, as seen on Debian (and Debian derived) mirrors, as well as the
// cached version in /var/lib/apt/lists/.
//
// This can be used to examine Binary packages contained in the Archive,
// to examine things like Built-Using, Depends, Tags or Binary packages
// present on an Architecture.
type BinaryIndex struct {
	Paragraph

	Package        string
	Source         string
	Version        version.Version
	InstalledSize  string `control:"Installed-Size"`
	Maintainer     string
	Architecture   dependency.Arch
	MultiArch      string `control:"Multi-Arch"`
	Description    string
	Homepage       string
	DescriptionMD5 string   `control:"Description-md5"`
	Tags           []string `delim:", "`
	Section        string
	Priority       string
	Filename       string
	Size           string
	MD5sum         string
	SHA1           string
	SHA256         string

	DebugBuildIds []string `control:"Build-Ids" delim:" "`
}

// Parse the Depends Dependency relation on this package.
func (index *BinaryIndex) GetDepends() dependency.Dependency {
	return index.getOptionalDependencyField("Depends")
}

// Parse the Depends Suggests relation on this package.
func (index *BinaryIndex) GetSuggests() dependency.Dependency {
	return index.getOptionalDependencyField("Suggests")
}

// Parse the Depends Breaks relation on this package.
func (index *BinaryIndex) GetBreaks() dependency.Dependency {
	return index.getOptionalDependencyField("Breaks")
}

// Parse the Depends Replaces relation on this package.
func (index *BinaryIndex) GetReplaces() dependency.Dependency {
	return index.getOptionalDependencyField("Replaces")
}

// Parse the Depends Pre-Depends relation on this package.
func (index *BinaryIndex) GetPreDepends() dependency.Dependency {
	return index.getOptionalDependencyField("Pre-Depends")
}

// Parse the Built-Depends relation on this package.
func (index *BinaryIndex) GetBuiltUsing() dependency.Dependency {
	return index.getOptionalDependencyField("Built-Using")
}

// SourcePackage returns the Debian source package name from which this binary
// Package was built, coping with the special cases Source == Package (skipped
// for efficiency) and binNMUs (Source contains version number).
func (index *BinaryIndex) SourcePackage() string {
	if index.Source == "" {
		return index.Package
	}
	if !strings.Contains(index.Source, " ") {
		return index.Source
	}
	return strings.Split(index.Source, " ")[0]
}

// BestChecksums can be included in a struct instead of e.g. ChecksumsSha256.
//
// BestChecksums uses cryptographically secure checksums, so that application
// code does not need to worry about that.
//
// The struct fields of BestChecksums need to be exported for the unmarshaling
// process but most not be used directly. Use the Checksums() accessor instead.
type BestChecksums struct {
	ChecksumsSha256 []SHA256FileHash `control:"Checksums-Sha256" delim:"\n" strip:"\n\r\t "`
	ChecksumsSha512 []SHA256FileHash `control:"Checksums-Sha512" delim:"\n" strip:"\n\r\t "`
}

// Checksums returns FileHashes of a cryptographically secure kind.
func (b *BestChecksums) Checksums() []FileHash {
	if len(b.ChecksumsSha256) > 0 {
		res := make([]FileHash, len(b.ChecksumsSha256))
		for i, c := range b.ChecksumsSha256 {
			res[i] = c.FileHash
		}
		return res
	}

	if len(b.ChecksumsSha512) > 0 {
		res := make([]FileHash, len(b.ChecksumsSha512))
		for i, c := range b.ChecksumsSha512 {
			res[i] = c.FileHash
		}
		return res
	}

	return nil
}

// The SourceIndex struct represents the exported APT Source index
// file, as seen on Debian (and Debian derived) mirrors, as well as the
// cached version in /var/lib/apt/lists/.
//
// This can be used to examine Source packages, to examine things like
// Binary packages built by Source packages, who maintains a package,
// or where to find the VCS repo for that package.
type SourceIndex struct {
	Paragraph

	Package  string
	Binaries []string `control:"Binary" delim:","`

	Version    version.Version
	Maintainer string
	Uploaders  string `delim:","`

	Architecture []dependency.Arch

	StandardsVersion string
	Format           string
	Files            []string `delim:"\n"`
	VcsBrowser       string   `control:"Vcs-Browser"`
	VcsGit           string   `control:"Vcs-Git"`
	VcsSvn           string   `control:"Vcs-Svn"`
	VcsBzr           string   `control:"Vcs-Bzr"`
	Homepage         string
	Directory        string
	Priority         string
	Section          string
}

// Parse the Depends Build-Depends relation on this package.
func (index *SourceIndex) GetBuildDepends() dependency.Dependency {
	return index.getOptionalDependencyField("Build-Depends")
}

// Parse the Depends Build-Depends-Arch relation on this package.
func (index *SourceIndex) GetBuildDependsArch() dependency.Dependency {
	return index.getOptionalDependencyField("Build-Depends-Arch")
}

// Parse the Depends Build-Depends-Indep relation on this package.
func (index *SourceIndex) GetBuildDependsIndep() dependency.Dependency {
	return index.getOptionalDependencyField("Build-Depends-Indep")
}

// Given a reader, parse out a list of BinaryIndex structs.
func ParseBinaryIndex(reader *bufio.Reader) (ret []BinaryIndex, err error) {
	ret = []BinaryIndex{}
	err = Unmarshal(&ret, reader)
	return ret, err
}

// Given a reader, parse out a list of SourceIndex structs.
func ParseSourceIndex(reader *bufio.Reader) (ret []SourceIndex, err error) {
	ret = []SourceIndex{}
	err = Unmarshal(&ret, reader)
	return ret, err
}

// vim: foldmethod=marker
