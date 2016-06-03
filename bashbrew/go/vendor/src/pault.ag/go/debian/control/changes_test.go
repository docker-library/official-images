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

func TestChangesParse(t *testing.T) {
	// Test Paragraph {{{
	reader := bufio.NewReader(strings.NewReader(`Format: 1.8
Date: Wed, 29 Apr 2015 21:29:13 -0400
Source: dput-ng
Binary: dput-ng python-dput dput-ng-doc
Architecture: source
Version: 1.9
Distribution: unstable
Urgency: medium
Maintainer: dput-ng Maintainers <dput-ng-maint@lists.alioth.debian.org>
Changed-By: Paul Tagliamonte <paultag@debian.org>
Description:
 dput-ng    - next generation Debian package upload tool
 dput-ng-doc - next generation Debian package upload tool (documentation)
 python-dput - next generation Debian package upload tool (Python library)
Closes: 783746
Changes:
 dput-ng (1.9) unstable; urgency=medium
 .
   * The "< jessfraz> ya!!!! jessie FTW" release
 .
   [ Sebastian Ramacher ]
   * Remove obsolete conffile /etc/dput.d/profiles/backports.json. Thanks to
     Jakub Wilk for spotting the obsolete conffile.
 .
   [ Luca Falavigna ]
   * Add support for Deb-o-Matic binnmu command.
 .
   [ Tristan Seligmann ]
   * Add jessie-backports to list of Debian codenames (closes: #783746).
Checksums-Sha1:
 cb136f28a8c971d4299cc68e8fdad93a8ca7daf3 1131 dput-ng_1.9.dsc
 77e97879793f57ee93cb3d59d8c5d16361f75b37 82504 dput-ng_1.9.tar.xz
Checksums-Sha256:
 2489ed1a2e052ccc4c321719a2394ac4b6958209f05b1531305d2a52173aa5c1 1131 dput-ng_1.9.dsc
 5ef401d9b67b009443f249aa79b952839c69a2b5437fbe957832599b655e1df0 82504 dput-ng_1.9.tar.xz
Files:
 a74c9e3e9fe05d480d24cd43b225ee0c 1131 devel extra dput-ng_1.9.dsc
 67e67e85a267c0c8110001b1a6cfc293 82504 devel extra dput-ng_1.9.tar.xz
`))
	// }}}
	changes, err := control.ParseChanges(reader, "")
	isok(t, err)
	assert(t, changes.Format == "1.8")
	assert(t, changes.ChangedBy == "Paul Tagliamonte <paultag@debian.org>")
	assert(t, len(changes.Binaries) == 3)
	assert(t, changes.Binaries[2] == "dput-ng-doc")

	assert(t, len(changes.Closes) == 1)
	assert(t, changes.Closes[0] == "783746")
}

func TestChangesParseFiles(t *testing.T) {
	// Test Paragraph {{{
	reader := bufio.NewReader(strings.NewReader(`Format: 1.8
Date: Wed, 29 Apr 2015 21:29:13 -0400
Source: dput-ng
Binary: dput-ng python-dput dput-ng-doc
Architecture: source
Version: 1.9
Distribution: unstable
Urgency: medium
Maintainer: dput-ng Maintainers <dput-ng-maint@lists.alioth.debian.org>
Changed-By: Paul Tagliamonte <paultag@debian.org>
Description:
 dput-ng    - next generation Debian package upload tool
 dput-ng-doc - next generation Debian package upload tool (documentation)
 python-dput - next generation Debian package upload tool (Python library)
Closes: 783746
Changes:
 dput-ng (1.9) unstable; urgency=medium
 .
   * The "< jessfraz> ya!!!! jessie FTW" release
 .
   [ Sebastian Ramacher ]
   * Remove obsolete conffile /etc/dput.d/profiles/backports.json. Thanks to
     Jakub Wilk for spotting the obsolete conffile.
 .
   [ Luca Falavigna ]
   * Add support for Deb-o-Matic binnmu command.
 .
   [ Tristan Seligmann ]
   * Add jessie-backports to list of Debian codenames (closes: #783746).
Checksums-Sha1:
 cb136f28a8c971d4299cc68e8fdad93a8ca7daf3 1131 dput-ng_1.9.dsc
 77e97879793f57ee93cb3d59d8c5d16361f75b37 82504 dput-ng_1.9.tar.xz
Checksums-Sha256:
 2489ed1a2e052ccc4c321719a2394ac4b6958209f05b1531305d2a52173aa5c1 1131 dput-ng_1.9.dsc
 5ef401d9b67b009443f249aa79b952839c69a2b5437fbe957832599b655e1df0 82504 dput-ng_1.9.tar.xz
Files:
 a74c9e3e9fe05d480d24cd43b225ee0c 1131 devel extra dput-ng_1.9.dsc
 67e67e85a267c0c8110001b1a6cfc293 82504 devel extra dput-ng_1.9.tar.xz
`))
	// }}}
	changes, err := control.ParseChanges(reader, "")
	isok(t, err)

	assert(t, len(changes.ChecksumsSha1) == 2)
	assert(t, len(changes.ChecksumsSha256) == 2)
	assert(t, len(changes.Files) == 2)
}

// vim: foldmethod=marker
