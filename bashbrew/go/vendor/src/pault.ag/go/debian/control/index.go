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

package control

import (
	"bufio"

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
