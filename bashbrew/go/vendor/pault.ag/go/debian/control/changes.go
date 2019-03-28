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
	"path"
	"path/filepath"
	"strconv"
	"strings"

	"pault.ag/go/debian/dependency"
	"pault.ag/go/debian/internal"
	"pault.ag/go/debian/version"
)

// {{{ .changes Files list entries

type FileListChangesFileHash struct {
	FileHash

	Component string
	Priority  string
}

func (c *FileListChangesFileHash) UnmarshalControl(data string) error {
	var err error
	c.Algorithm = "md5"
	vals := strings.Split(data, " ")
	if len(vals) < 5 {
		return fmt.Errorf("Error: Unknown File List Hash line: '%s'", data)
	}

	c.Hash = vals[0]
	c.Size, err = strconv.ParseInt(vals[1], 10, 64)
	if err != nil {
		return err
	}
	c.Component = vals[2]
	c.Priority = vals[3]

	c.Filename = vals[4]
	return nil
}

// }}}

// The Changes struct is the default encapsulation of the Debian .changes
// package filetype.This struct contains an anonymous member of type Paragraph,
// allowing you to use the standard .Values and .Order of the Paragraph type.
//
// The .changes files are used by the Debian archive maintenance software to
// process updates to packages. They consist of a single paragraph, possibly
// surrounded by a PGP signature. That paragraph contains information from the
// debian/control file and other data about the source package gathered via
// debian/changelog and debian/rules.
type Changes struct {
	Paragraph

	Filename string

	Format          string
	Source          string
	Binaries        []string          `control:"Binary" delim:" "`
	Architectures   []dependency.Arch `control:"Architecture"`
	Version         version.Version
	Origin          string
	Distribution    string
	Urgency         string
	Maintainer      string
	ChangedBy       string `control:"Changed-By"`
	Closes          []string
	Changes         string
	ChecksumsSha1   []SHA1FileHash            `control:"Checksums-Sha1" delim:"\n" strip:"\n\r\t "`
	ChecksumsSha256 []SHA256FileHash          `control:"Checksums-Sha256" delim:"\n" strip:"\n\r\t "`
	Files           []FileListChangesFileHash `control:"Files" delim:"\n" strip:"\n\r\t "`
}

// Given a path on the filesystem, Parse the file off the disk and return
// a pointer to a brand new Changes struct, unless error is set to a value
// other than nil.
func ParseChangesFile(path string) (ret *Changes, err error) {
	path, err = filepath.Abs(path)
	if err != nil {
		return nil, err
	}

	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	return ParseChanges(bufio.NewReader(f), path)
}

// Given a bufio.Reader, consume the Reader, and return a Changes object
// for use. The "path" argument is used to set Changes.Filename, which
// is used by Changes.GetDSC, Changes.Remove, Changes.Move and Changes.Copy to
// figure out where all the files on the filesystem are. This value can be set
// to something invalid if you're not using those functions.
func ParseChanges(reader *bufio.Reader, path string) (*Changes, error) {
	ret := &Changes{Filename: path}
	return ret, Unmarshal(ret, reader)
}

// Return a list of FileListChangesFileHash entries from the `changes.Files`
// entry, with the exception that each `Filename` will be joined to the root
// directory of the Changes file.
func (changes *Changes) AbsFiles() []FileListChangesFileHash {
	ret := []FileListChangesFileHash{}

	baseDir := filepath.Dir(changes.Filename)
	for _, hash := range changes.Files {
		hash.Filename = path.Join(baseDir, hash.Filename)
		ret = append(ret, hash)
	}

	return ret
}

// Return a DSC struct for the DSC listed in the .changes file. This requires
// Changes.Filename to be correctly set, and for the .dsc file to exist
// in the correct place next to the .changes.
//
// This function may also return an error if the given .changes does not
// include the .dsc (binary-only upload)
func (changes *Changes) GetDSC() (*DSC, error) {
	for _, file := range changes.Files {
		if strings.HasSuffix(file.Filename, ".dsc") {

			// Right, now lets resolve the absolute path.
			baseDir := filepath.Dir(changes.Filename)

			dsc, err := ParseDscFile(baseDir + "/" + file.Filename)
			if err != nil {
				return nil, err
			}
			return dsc, nil
		}
	}
	return nil, fmt.Errorf("No .dsc file in .changes")
}

// Copy the .changes file and all referenced files to the directory
// listed by the dest argument. This function will error out if the dest
// argument is not a directory, or if there is an IO operation in transfer.
//
// This function will always move .changes last, making it suitable to
// be used to move something into an incoming directory with an inotify
// hook. This will also mutate Changes.Filename to match the new location.
func (changes *Changes) Copy(dest string) error {
	if file, err := os.Stat(dest); err == nil && !file.IsDir() {
		return fmt.Errorf("Attempting to move .changes to a non-directory")
	}

	for _, file := range changes.AbsFiles() {
		dirname := filepath.Base(file.Filename)
		err := internal.Copy(file.Filename, dest+"/"+dirname)
		if err != nil {
			return err
		}
	}

	dirname := filepath.Base(changes.Filename)
	err := internal.Copy(changes.Filename, dest+"/"+dirname)
	changes.Filename = dest + "/" + dirname
	return err
}

// Move the .changes file and all referenced files to the directory
// listed by the dest argument. This function will error out if the dest
// argument is not a directory, or if there is an IO operation in transfer.
//
// This function will always move .changes last, making it suitable to
// be used to move something into an incoming directory with an inotify
// hook. This will also mutate Changes.Filename to match the new location.
func (changes *Changes) Move(dest string) error {
	if file, err := os.Stat(dest); err == nil && !file.IsDir() {
		return fmt.Errorf("Attempting to move .changes to a non-directory")
	}

	for _, file := range changes.AbsFiles() {
		dirname := filepath.Base(file.Filename)
		err := os.Rename(file.Filename, dest+"/"+dirname)
		if err != nil {
			return err
		}
	}

	dirname := filepath.Base(changes.Filename)
	err := os.Rename(changes.Filename, dest+"/"+dirname)
	changes.Filename = dest + "/" + dirname
	return err
}

// Remove the .changes file and any associated files. This function will
// always remove the .changes last, in the event there are filesystem i/o errors
// on removing associated files.
func (changes *Changes) Remove() error {
	for _, file := range changes.AbsFiles() {
		err := os.Remove(file.Filename)
		if err != nil {
			return err
		}
	}
	return os.Remove(changes.Filename)
}

// vim: foldmethod=marker
