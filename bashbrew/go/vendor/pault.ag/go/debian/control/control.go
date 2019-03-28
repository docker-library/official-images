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
	"fmt"
	"os"
	"path/filepath"

	"pault.ag/go/debian/dependency"
)

// Encapsulation for a debian/control file, which is a series of RFC2822-like
// blocks, starting with a Source control paragraph, and then a series of
// Binary control paragraphs.
//
// The debian/control file contains the most vital (and version-independent)
// information about the source package and about the binary packages it
// creates.
//
// The first paragraph of the control file contains information about the source
// package in general. The subsequent sets each describe a binary package that
// the source tree builds.
type Control struct {
	Filename string

	Source   SourceParagraph
	Binaries []BinaryParagraph
}

// Encapsulation for a debian/control Source entry. This contains information
// that will wind up in the .dsc and friends. Really quite fun!
type SourceParagraph struct {
	Paragraph

	Maintainer  string
	Uploaders   []string `delim:","`
	Source      string
	Priority    string
	Section     string
	Description string

	BuildDepends        dependency.Dependency `control:"Build-Depends"`
	BuildDependsIndep   dependency.Dependency `control:"Build-Depends-Indep"`
	BuildConflicts      dependency.Dependency `control:"Build-Conflicts"`
	BuildConflictsIndep dependency.Dependency `control:"Build-Conflicts-Indep"`
}

// Return a list of all entities that are responsible for the package's
// well being. The 0th element is always the package's Maintainer,
// with any Uploaders following.
func (s *SourceParagraph) Maintainers() []string {
	return append([]string{s.Maintainer}, s.Uploaders...)
}

// Encapsulation for a debian/control Binary control entry. This contains
// information that will be eventually put lovingly into the .deb file
// after it's built on a given Arch.
type BinaryParagraph struct {
	Paragraph
	Architectures []dependency.Arch `control:"Architecture"`
	Package       string
	Priority      string
	Section       string
	Essential     bool
	Description   string

	Depends    dependency.Dependency
	Recommends dependency.Dependency
	Suggests   dependency.Dependency
	Enhances   dependency.Dependency
	PreDepends dependency.Dependency `control:"Pre-Depends"`

	Breaks    dependency.Dependency
	Conflicts dependency.Dependency
	Replaces  dependency.Dependency

	BuiltUsing dependency.Dependency `control:"Built-Using"`
}

func (para *Paragraph) getDependencyField(field string) (*dependency.Dependency, error) {
	if val, ok := para.Values[field]; ok {
		return dependency.Parse(val)
	}
	return nil, fmt.Errorf("Field `%s' Missing", field)
}

func (para *Paragraph) getOptionalDependencyField(field string) dependency.Dependency {
	val := para.Values[field]
	dep, err := dependency.Parse(val)
	if err != nil {
		return dependency.Dependency{}
	}
	return *dep
}

// Given a path on the filesystem, Parse the file off the disk and return
// a pointer to a brand new Control struct, unless error is set to a value
// other than nil.
func ParseControlFile(path string) (ret *Control, err error) {
	path, err = filepath.Abs(path)
	if err != nil {
		return nil, err
	}

	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	ret, err = ParseControl(bufio.NewReader(f), path)
	if err != nil {
		return nil, err
	}
	return ret, nil
}

// Given a bufio.Reader, consume the Reader, and return a Control object
// for use.
func ParseControl(reader *bufio.Reader, path string) (*Control, error) {
	ret := Control{
		Filename: path,
		Binaries: []BinaryParagraph{},
		Source:   SourceParagraph{},
	}

	if err := Unmarshal(&ret.Source, reader); err != nil {
		return nil, err
	}
	if err := Unmarshal(&ret.Binaries, reader); err != nil {
		return nil, err
	}

	return &ret, nil
}

// vim: foldmethod=marker
