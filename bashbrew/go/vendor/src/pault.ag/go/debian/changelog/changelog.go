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

package changelog

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"pault.ag/go/debian/version"
)

// A ChangelogEntry is the encapsulation for each entry for a given version
// in a series of uploads.
type ChangelogEntry struct {
	Source    string
	Version   version.Version
	Target    string
	Arguments map[string]string
	Changelog string
	ChangedBy string
	When      time.Time
}

const whenLayout = time.RFC1123Z // "Mon, 02 Jan 2006 15:04:05 -0700"

type ChangelogEntries []ChangelogEntry

func trim(line string) string {
	return strings.Trim(line, "\n\r\t ")
}

func partition(line, delim string) (string, string) {
	entries := strings.SplitN(line, delim, 2)
	if len(entries) != 2 {
		return line, ""
	}
	return entries[0], entries[1]

}

func ParseOne(reader *bufio.Reader) (*ChangelogEntry, error) {
	changeLog := ChangelogEntry{}

	var header string
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return nil, err
		}
		if line == "\n" {
			continue
		}
		if !strings.HasPrefix(line, " ") {
			/* Great. Let's work with this. */
			header = line
			break
		} else {
			return nil, fmt.Errorf("Unexpected line: %s", line)
		}
	}

	/* OK, so, we have a header. Let's run with it
	 * hello (2.10-1) unstable; urgency=low */

	arguments, options := partition(header, ";")
	/* Arguments: hello (2.10-1) unstable
	 * Options:   urgency=low, other=bar */

	source, remainder := partition(arguments, "(")
	versionString, suite := partition(remainder, ")")

	var err error

	changeLog.Source = trim(source)
	changeLog.Version, err = version.Parse(trim(versionString))
	if err != nil {
		return nil, err
	}
	changeLog.Target = trim(suite)

	changeLog.Arguments = map[string]string{}

	for _, entry := range strings.Split(options, ",") {
		key, value := partition(trim(entry), "=")
		changeLog.Arguments[trim(key)] = trim(value)
	}

	var signoff string
	/* OK, we've got the header. Let's zip down. */
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			return nil, err
		}
		if !strings.HasPrefix(line, " ") && trim(line) != "" {
			return nil, fmt.Errorf("Error! Didn't get ending line!")
		}

		if strings.HasPrefix(line, " -- ") {
			signoff = line
			break
		}

		changeLog.Changelog = changeLog.Changelog + line
	}

	/* Right, so we have a signoff line */
	_, signoff = partition(signoff, "--")  /* Get rid of the leading " -- " */
	whom, when := partition(signoff, "  ") /* Split on the "  " */
	changeLog.ChangedBy = trim(whom)
	changeLog.When, err = time.Parse(whenLayout, trim(when))
	if err != nil {
		return nil, fmt.Errorf("Failed parsing When %q: %v", when, err)
	}

	return &changeLog, nil
}

func ParseFileOne(path string) (*ChangelogEntry, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	return ParseOne(bufio.NewReader(f))
}

func Parse(reader io.Reader) (ChangelogEntries, error) {
	stream := bufio.NewReader(reader)
	ret := ChangelogEntries{}
	for {
		entry, err := ParseOne(stream)
		if err == io.EOF {
			break
		}
		if err != nil {
			return ChangelogEntries{}, err
		}
		ret = append(ret, *entry)
	}
	return ret, nil
}

func ParseFile(path string) (ChangelogEntries, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	return Parse(bufio.NewReader(f))
}

// vim: foldmethod=marker
