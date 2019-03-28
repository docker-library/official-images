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
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"strings"
	"unicode"

	"golang.org/x/crypto/openpgp"
	"golang.org/x/crypto/openpgp/clearsign"
)

// A Paragraph is a block of RFC2822-like key value pairs. This struct contains
// two methods to fetch values, a Map called Values, and a Slice called
// Order, which maintains the ordering as defined in the RFC2822-like block
type Paragraph struct {
	Values map[string]string
	Order  []string
}

// Paragraph Helpers {{{

func (p *Paragraph) Set(key, value string) {
	if _, found := p.Values[key]; found {
		/* We've got the key */
		p.Values[key] = value
		return
	}
	/* Otherwise, go ahead and set it in the order and dict,
	 * and call it a day */
	p.Order = append(p.Order, key)
	p.Values[key] = value
}

func (p *Paragraph) WriteTo(out io.Writer) error {
	for _, key := range p.Order {
		value := p.Values[key]

		value = strings.Replace(value, "\n", "\n ", -1)
		value = strings.Replace(value, "\n \n", "\n .\n", -1)

		if _, err := out.Write(
			[]byte(fmt.Sprintf("%s: %s\n", key, value)),
		); err != nil {
			return err
		}
	}
	return nil
}

func (p *Paragraph) Update(other Paragraph) Paragraph {
	ret := Paragraph{
		Order:  []string{},
		Values: map[string]string{},
	}

	seen := map[string]bool{}

	for _, el := range p.Order {
		ret.Order = append(ret.Order, el)
		ret.Values[el] = p.Values[el]
		seen[el] = true
	}

	for _, el := range other.Order {
		if _, ok := seen[el]; !ok {
			ret.Order = append(ret.Order, el)
			seen[el] = true
		}
		ret.Values[el] = other.Values[el]
	}

	return ret
}

// }}}

// ParagraphReader {{{

// Wrapper to allow iteration on a set of Paragraphs without consuming them
// all into memory at one time. This is also the level in which data is
// signed, so information such as the entity that signed these documents
// can be read by calling the `.Signer` method on this struct. The next
// unread Paragraph can be returned by calling the `.Next` method on this
// struct.
type ParagraphReader struct {
	reader *bufio.Reader
	signer *openpgp.Entity
}

// {{{ NewParagraphReader

// Create a new ParagraphReader from the given `io.Reader`, and `keyring`.
// if `keyring` is set to `nil`, this will result in all OpenPGP signature
// checking being disabled. *including* that the contents match!
//
// Also keep in mind, `reader` may be consumed 100% in memory due to
// the underlying OpenPGP API being hella fiddly.
func NewParagraphReader(reader io.Reader, keyring *openpgp.EntityList) (*ParagraphReader, error) {
	bufioReader := bufio.NewReader(reader)
	ret := ParagraphReader{
		reader: bufioReader,
		signer: nil,
	}

	// OK. We have a document. Now, let's peek ahead and see if we've got an
	// OpenPGP Clearsigned set of Paragraphs. If we do, we're going to go ahead
	// and do the decode dance.
	line, _ := bufioReader.Peek(15)
	if string(line) != "-----BEGIN PGP " {
		return &ret, nil
	}

	if err := ret.decodeClearsig(keyring); err != nil {
		return nil, err
	}
	return &ret, nil
}

// }}}

// Signer {{{

// Return the Entity (if one exists) that signed this set of Paragraphs.
func (p *ParagraphReader) Signer() *openpgp.Entity {
	return p.signer
}

// }}}

// All {{{

func (p *ParagraphReader) All() ([]Paragraph, error) {
	ret := []Paragraph{}
	for {
		paragraph, err := p.Next()
		if err == io.EOF {
			return ret, nil
		} else if err != nil {
			return []Paragraph{}, err
		}
		ret = append(ret, *paragraph)
	}
}

// }}}

// Next {{{

// Consume the io.Reader and return the next parsed Paragraph, modulo
// garbage lines causing us to return an error.
func (p *ParagraphReader) Next() (*Paragraph, error) {
	paragraph := Paragraph{
		Order:  []string{},
		Values: map[string]string{},
	}
	var lastKey string

	for {
		line, err := p.reader.ReadString('\n')
		if err == io.EOF && line != "" {
			err = nil
			line = line + "\n"
			/* We'll clean up the last of the buffer. */
		}
		if err == io.EOF {
			/* Let's return the parsed paragraph if we have it */
			if len(paragraph.Order) > 0 {
				return &paragraph, nil
			}
			/* Else, let's go ahead and drop the EOF out raw */
			return nil, err
		} else if err != nil {
			return nil, err
		}

		if line == "\n" || line == "\r\n" {
			/* Lines are ended by a blank line; so we're able to go ahead
			 * and return this guy as-is. All set. Done. Finished. */
			return &paragraph, nil
		}

		if strings.HasPrefix(line, "#") {
			continue // skip comments
		}

		/* Right, so we have a line in one of the following formats:
		 *
		 * "Key: Value"
		 * " Foobar"
		 *
		 * Foobar is seen as a continuation of the last line, and the
		 * Key line is a Key/Value mapping.
		 */

		if strings.HasPrefix(line, " ") || strings.HasPrefix(line, "\t") {
			/* This is a continuation line; so we're going to go ahead and
			 * clean it up, and throw it into the list. We're going to remove
			 * the first character (which we now know is whitespace), and if
			 * it's a line that only has a dot on it, we'll remove that too
			 * (since " .\n" is actually "\n"). We only trim off space on the
			 * right hand, because indentation under the whitespace is up to
			 * the data format. Not us. */

			/* TrimFunc(line[1:], unicode.IsSpace) is identical to calling
			 * TrimSpace. */
			line = strings.TrimRightFunc(line[1:], unicode.IsSpace)

			if line == "." {
				line = ""
			}

			if paragraph.Values[lastKey] == "" {
				paragraph.Values[lastKey] = line + "\n"
			} else {
				if !strings.HasSuffix(paragraph.Values[lastKey], "\n") {
					paragraph.Values[lastKey] = paragraph.Values[lastKey] + "\n"
				}
				paragraph.Values[lastKey] = paragraph.Values[lastKey] + line + "\n"
			}
			continue
		}

		/* So, if we're here, we've got a key line. Let's go ahead and split
		 * this on the first key, and set that guy */
		els := strings.SplitN(line, ":", 2)
		if len(els) != 2 {
			return nil, fmt.Errorf("Bad line: '%s' has no ':'", line)
		}

		/* We'll go ahead and take off any leading spaces */
		lastKey = strings.TrimSpace(els[0])
		value := strings.TrimSpace(els[1])

		paragraph.Order = append(paragraph.Order, lastKey)
		paragraph.Values[lastKey] = value
	}
}

// }}}

// decodeClearsig {{{

// Internal method to read an OpenPGP Clearsigned document, store related
// OpenPGP information onto the shell Struct, and return any errors that
// we encounter along the way, such as an invalid signature, unknown
// signer, or incomplete document. If `keyring` is `nil`, checking of the
// signed data is *not* preformed.
func (p *ParagraphReader) decodeClearsig(keyring *openpgp.EntityList) error {
	// One *massive* downside here is that the OpenPGP module in Go operates
	// on byte arrays in memory, and *not* on Readers and Writers. This is a
	// huge PITA because it doesn't need to be that way, and this forces
	// clearsigned documents into memory. Which fucking sucks. But here
	// we are. It's likely worth a bug or two on this.

	signedData, err := ioutil.ReadAll(p.reader)
	if err != nil {
		return err
	}

	block, _ := clearsign.Decode(signedData)
	/* We're only interested in the first block. This may change in the
	 * future, in which case, we should likely set reader back to
	 * the remainder, and return that out to put through another
	 * ParagraphReader, since it may have a different signer. */

	if keyring == nil {
		/* As a special case, if the keyring is nil, we can go ahead
		 * and assume this data isn't intended to be checked against the
		 * keyring. So, we'll just pass on through. */
		p.reader = bufio.NewReader(bytes.NewBuffer(block.Bytes))
		return nil
	}

	/* Now, we have to go ahead and check that the signature is valid and
	 * relates to an entity we have in our keyring */
	signer, err := openpgp.CheckDetachedSignature(
		keyring,
		bytes.NewReader(block.Bytes),
		block.ArmoredSignature.Body,
	)

	if err != nil {
		return err
	}

	p.signer = signer
	p.reader = bufio.NewReader(bytes.NewBuffer(block.Bytes))

	return nil
}

// }}}

// }}}

// vim: foldmethod=marker
