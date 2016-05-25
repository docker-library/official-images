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
	"fmt"
	"strconv"
	"strings"

	"pault.ag/go/debian/transput"
)

// A FileHash is an entry as found in the Files, Checksum-Sha1, and
// Checksum-Sha256 entry for the .dsc or .changes files.
type FileHash struct {
	// cb136f28a8c971d4299cc68e8fdad93a8ca7daf3 1131 dput-ng_1.9.dsc
	Algorithm string
	Hash      string
	Size      int64
	Filename  string
}

func FileHashFromHasher(path string, hasher transput.Hasher) FileHash {
	return FileHash{
		Algorithm: hasher.Name(),
		Hash:      fmt.Sprintf("%x", hasher.Sum(nil)),
		Size:      hasher.Size(),
		Filename:  path,
	}
}

type FileHashes []FileHash

// {{{ Hash File implementations

func (c FileHash) marshalControl() (string, error) {
	return fmt.Sprintf("%s %d %s", c.Hash, c.Size, c.Filename), nil
}

func (c *FileHash) unmarshalControl(algorithm, data string) error {
	var err error
	c.Algorithm = algorithm
	vals := strings.Fields(data)
	if len(data) < 4 {
		return fmt.Errorf("Error: Unknown Debian Hash line: '%s'", data)
	}

	c.Hash = vals[0]
	c.Size, err = strconv.ParseInt(vals[1], 10, 64)
	if err != nil {
		return err
	}
	c.Filename = vals[2]
	return nil
}

// {{{ MD5 FileHash

type MD5FileHash struct{ FileHash }

func (c *MD5FileHash) UnmarshalControl(data string) error {
	return c.unmarshalControl("md5", data)
}

func (c MD5FileHash) MarshalControl() (string, error) {
	return c.marshalControl()
}

// }}}

// {{{ SHA1 FileHash

type SHA1FileHash struct{ FileHash }

func (c *SHA1FileHash) UnmarshalControl(data string) error {
	return c.unmarshalControl("sha1", data)
}

func (c SHA1FileHash) MarshalControl() (string, error) {
	return c.marshalControl()
}

// }}}

// {{{ SHA256 FileHash

type SHA256FileHash struct{ FileHash }

func (c *SHA256FileHash) UnmarshalControl(data string) error {
	return c.unmarshalControl("sha256", data)
}

func (c SHA256FileHash) MarshalControl() (string, error) {
	return c.marshalControl()
}

// }}}

// {{{ SHA512 FileHash

type SHA512FileHash struct{ FileHash }

func (c *SHA512FileHash) UnmarshalControl(data string) error {
	return c.unmarshalControl("sha512", data)
}

func (c SHA512FileHash) MarshalControl() (string, error) {
	return c.marshalControl()
}

// }}}

// }}}

// vim: foldmethod=marker
