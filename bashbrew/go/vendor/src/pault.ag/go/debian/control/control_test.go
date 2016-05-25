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

package control_test

import (
	"bufio"
	"strings"
	"testing"

	"pault.ag/go/debian/control"
)

/*
 *
 */

func TestDependencyControlParse(t *testing.T) {
	// Test Control {{{
	reader := bufio.NewReader(strings.NewReader(`Source: fbautostart
Section: misc
Priority: optional
Maintainer: Paul Tagliamonte <paultag@ubuntu.com>
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.3
Homepage: https://launchpad.net/fbautostart
Vcs-Git: git://git.debian.org/collab-maint/fbautostart.git
Vcs-Browser: http://git.debian.org/?p=collab-maint/fbautostart.git

Package: fbautostart
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}
Description: XDG compliant autostarting app for Fluxbox
 The fbautostart app was designed to have little to no overhead, while
 still maintaining the needed functionality of launching applications
 according to the XDG spec.
 .
 This package contains support for GNOME and KDE.
`))
	// }}}
	c, err := control.ParseControl(reader, "")
	isok(t, err)
	assert(t, c != nil)
	assert(t, len(c.Binaries) == 1)

	assert(t, c.Source.Maintainer == "Paul Tagliamonte <paultag@ubuntu.com>")
	assert(t, c.Source.Source == "fbautostart")

	depends := c.Source.BuildDepends

	assert(t, len(c.Source.Maintainers()) == 1)
	assert(t, len(c.Source.Uploaders) == 0)

	assert(t, len(c.Source.BuildDepends.Relations) == 1)
	assert(t, len(c.Source.BuildDependsIndep.Relations) == 0)
	assert(t, len(c.Source.BuildConflicts.Relations) == 0)
	assert(t, len(c.Source.BuildConflictsIndep.Relations) == 0)

	assert(t, depends.Relations[0].Possibilities[0].Name == "debhelper")
	assert(t, depends.Relations[0].Possibilities[0].Version.Number == "9")
	assert(t, depends.Relations[0].Possibilities[0].Version.Operator == ">=")

	assert(t, len(c.Binaries[0].Architectures) == 1)

	assert(t, c.Binaries[0].Architectures[0].CPU == "any")
	assert(t, c.Binaries[0].Package == "fbautostart")
}

func TestMaintainersParse(t *testing.T) {
	// Test Control {{{
	reader := bufio.NewReader(strings.NewReader(`Source: fbautostart
Section: misc
Priority: optional
Maintainer: Paul Tagliamonte <paultag@ubuntu.com>
Uploaders: John Doe <jdoe@example.com>,
 Foo Bar <fnord@baz.fnord>
Build-Depends: debhelper (>= 9)
Standards-Version: 3.9.3
Homepage: https://launchpad.net/fbautostart
Vcs-Git: git://git.debian.org/collab-maint/fbautostart.git
Vcs-Browser: http://git.debian.org/?p=collab-maint/fbautostart.git

Package: fbautostart
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, test
Description: XDG compliant autostarting app for Fluxbox
 The fbautostart app was designed to have little to no overhead, while
 still maintaining the needed functionality of launching applications
 according to the XDG spec.
 .
 This package contains support for GNOME and KDE.

Package: fbautostart-foo
Architecture: amd64 sparc kfreebsd-any
Depends: ${shlibs:Depends}, ${misc:Depends}, test
Description: XDG compliant autostarting app for Fluxbox
 The fbautostart app was designed to have little to no overhead, while
 still maintaining the needed functionality of launching applications
 according to the XDG spec.
 .
 This package contains support for GNOME and KDE.
`))
	// }}}
	c, err := control.ParseControl(reader, "")
	isok(t, err)
	assert(t, c != nil)
	assert(t, len(c.Binaries) == 2)
	assert(t, len(c.Source.Maintainers()) == 3)

	arches := c.Binaries[1].Architectures
	assert(t, len(arches) == 3)
}

// vim: foldmethod=marker
