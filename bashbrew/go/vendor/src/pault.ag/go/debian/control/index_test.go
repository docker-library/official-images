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

func TestSourceIndexParse(t *testing.T) {
	// Test Source Index {{{
	reader := bufio.NewReader(strings.NewReader(`Package: fbasics
Binary: r-cran-fbasics
Version: 3011.87-2
Maintainer: Dirk Eddelbuettel <edd@debian.org>
Build-Depends: debhelper (>= 7.0.0), r-base-dev (>= 3.2.0), cdbs, r-cran-mass, r-cran-timedate, r-cran-timeseries (>= 2100.84), r-cran-stabledist, xvfb, xauth, xfonts-base, r-cran-gss
Architecture: any
Standards-Version: 3.9.6
Format: 1.0
Files:
 8bb6eda1e01be26c5446d21c64420e7f 1818 fbasics_3011.87-2.dsc
 f9f6e7f84bff1ce90cdc5890b9a3f6b5 932125 fbasics_3011.87.orig.tar.gz
 afc2e90feddb30baf96babfc767dff60 3818 fbasics_3011.87-2.diff.gz
Checksums-Sha1:
 45137d257a8bf2ed01b1809add5641bea7353072 1818 fbasics_3011.87-2.dsc
 cb0d17a055b7eaea72b14938e2948e603011b548 932125 fbasics_3011.87.orig.tar.gz
 03c215003ddca5a9651d315902d2d3ee67e8c37a 3818 fbasics_3011.87-2.diff.gz
Checksums-Sha256:
 0a4f8cc793903e366a84379a651bf1a4542d50823b4bd4e038efcdb85a1af95e 1818 fbasics_3011.87-2.dsc
 f0a79bb3931cd145677c947d8cd87cf60869f604933e685e74225bb01ad992f4 932125 fbasics_3011.87.orig.tar.gz
 e087596fc0ac2bca6cf9ad531afc4329e75b2d7b26f0a0334be8dcb29d94f4ee 3818 fbasics_3011.87-2.diff.gz
Homepage: http://www.Rmetrics.org
Package-List: 
 r-cran-fbasics deb gnu-r optional arch=any
Directory: pool/main/f/fbasics
Priority: source
Section: gnu-r

Package: fbautostart
Binary: fbautostart
Version: 2.718281828-1
Maintainer: Paul Tagliamonte <paultag@ubuntu.com>
Build-Depends: debhelper (>= 9)
Architecture: any
Standards-Version: 3.9.3
Format: 3.0 (quilt)
Files:
 9d610c30f96623cff07bd880e5cca12f 1899 fbautostart_2.718281828-1.dsc
 06495f9b23b1c9b1bf35c2346cb48f63 92748 fbautostart_2.718281828.orig.tar.gz
 3b0e6dd201d5036f6d1b80f0ac4e1e7d 2396 fbautostart_2.718281828-1.debian.tar.gz
Vcs-Browser: http://git.debian.org/?p=collab-maint/fbautostart.git
Vcs-Git: git://git.debian.org/collab-maint/fbautostart.git
Checksums-Sha1:
 3e0dcbe5549f47f35eb7f8960c0ada33bbc3f48b 1899 fbautostart_2.718281828-1.dsc
 bc36310c15edc9acf48f0a1daf548bcc6f861372 92748 fbautostart_2.718281828.orig.tar.gz
 af4f1950dd8ed5bb7bd8952c8c00ffdd42eadb46 2396 fbautostart_2.718281828-1.debian.tar.gz
Checksums-Sha256:
 0adda8e19e217dd2fa69d0842dcef0fa250bd428b1e43e78723d76909e5f51cc 1899 fbautostart_2.718281828-1.dsc
 bb2fdfd4a38505905222ee02d8236a594bdf6eaefca23462294cacda631745c1 92748 fbautostart_2.718281828.orig.tar.gz
 49f402ff3a72653e63542037be9f4da56e318e412d26d4154f9336fb88df3519 2396 fbautostart_2.718281828-1.debian.tar.gz
Homepage: https://launchpad.net/fbautostart
Package-List: 
 fbautostart deb misc optional
Directory: pool/main/f/fbautostart
Priority: source
Section: misc
`))
	// }}}
	sources, err := control.ParseSourceIndex(reader)
	isok(t, err)
	assert(t, len(sources) == 2)

	fbautostart := sources[1]
	assert(t, fbautostart.Maintainer == "Paul Tagliamonte <paultag@ubuntu.com>")
	assert(t, fbautostart.VcsGit == "git://git.debian.org/collab-maint/fbautostart.git")
}

func TestBinaryIndexParse(t *testing.T) {
	// Test Binary Index {{{
	reader := bufio.NewReader(strings.NewReader(`Package: android-tools-fastboot
Source: android-tools
Version: 4.2.2+git20130529-5.1
Installed-Size: 184
Maintainer: Android tools Maintainer <android-tools-devel@lists.alioth.debian.org>
Architecture: amd64
Depends: libc6 (>= 2.14), libselinux1 (>= 2.0.65), zlib1g (>= 1:1.2.3.4)
Description: Android Fastboot protocol CLI tool
Homepage: http://developer.android.com/guide/developing/tools/adb.html
Description-md5: 56b9309fa4fb2f92a313a815c7d7b5d3
Section: devel
Priority: extra
Filename: pool/main/a/android-tools/android-tools-fastboot_4.2.2+git20130529-5.1_amd64.deb
Size: 56272
MD5sum: cd858b3257b250747822ebeea6c69f4a
SHA1: 9d45825f07b2bc52edc787ba78966db0d4a48e69
SHA256: c094b7e53eb030957cdfab865f68c817d65bf6a1345b10d2982af38d042c3e84

Package: android-tools-fsutils
Source: android-tools
Version: 4.2.2+git20130529-5.1
Installed-Size: 504
Maintainer: Android tools Maintainer <android-tools-devel@lists.alioth.debian.org>
Architecture: amd64
Depends: python:any, libc6 (>= 2.14), libselinux1 (>= 2.0.65), zlib1g (>= 1:1.2.3.4)
Description: Android ext4 utilities with sparse support
Homepage: http://developer.android.com/guide/developing/tools/adb.html
Description-md5: 23135bc652e7b302961741f9bcff8397
Section: devel
Priority: extra
Filename: pool/main/a/android-tools/android-tools-fsutils_4.2.2+git20130529-5.1_amd64.deb
Size: 71900
MD5sum: 996732fc455acdcf4682de4f80a2dc95
SHA1: 5c2320913cc7cc46305390d8b3a7ef51f0a174ef
SHA256: 270ad759d1fef9cedf894c42b5f559d7386aa1ec4de4cc3880eb44fe8c53c833

Package: androidsdk-ddms
Source: androidsdk-tools
Version: 22.2+git20130830~92d25d6-1
Installed-Size: 211
Maintainer: Debian Java Maintainers <pkg-java-maintainers@lists.alioth.debian.org>
Architecture: all
Depends: libandroidsdk-swtmenubar-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-ddmlib-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-ddmuilib-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-sdkstats-java (= 22.2+git20130830~92d25d6-1), eclipse-rcp
Description: Graphical debugging tool for Android
Homepage: http://developer.android.com/tools/help/index.html
Description-md5: a2f559d2abf6ebb1d25bc3929d5aa2b0
Section: java
Priority: extra
Filename: pool/main/a/androidsdk-tools/androidsdk-ddms_22.2+git20130830~92d25d6-1_all.deb
Size: 132048
MD5sum: fde05f3552457e91a415c99ab2a2a514
SHA1: 82b05c97163ccfbbb10a52a5514882412a13ee43
SHA256: fa53e4f50349c5c9b564b8dc1da86c503b0baf56ab95a4ef6e204b6f77bfe70c
`))
	// }}}
	sources, err := control.ParseBinaryIndex(reader)
	isok(t, err)
	assert(t, len(sources) == 3)

	assert(t, sources[2].Source == "androidsdk-tools")
	assert(t, sources[2].Filename == "pool/main/a/androidsdk-tools/androidsdk-ddms_22.2+git20130830~92d25d6-1_all.deb")
}

func TestBinaryIndexDependsParse(t *testing.T) {
	// Test Binary Index {{{
	reader := bufio.NewReader(strings.NewReader(`Package: androidsdk-ddms
Source: androidsdk-tools
Version: 22.2+git20130830~92d25d6-1
Installed-Size: 211
Maintainer: Debian Java Maintainers <pkg-java-maintainers@lists.alioth.debian.org>
Architecture: all
Depends: libandroidsdk-swtmenubar-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-ddmlib-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-ddmuilib-java (= 22.2+git20130830~92d25d6-1), libandroidsdk-sdkstats-java (= 22.2+git20130830~92d25d6-1), eclipse-rcp
Description: Graphical debugging tool for Android
Homepage: http://developer.android.com/tools/help/index.html
Description-md5: a2f559d2abf6ebb1d25bc3929d5aa2b0
Section: java
Priority: extra
Filename: pool/main/a/androidsdk-tools/androidsdk-ddms_22.2+git20130830~92d25d6-1_all.deb
Size: 132048
MD5sum: fde05f3552457e91a415c99ab2a2a514
SHA1: 82b05c97163ccfbbb10a52a5514882412a13ee43
SHA256: fa53e4f50349c5c9b564b8dc1da86c503b0baf56ab95a4ef6e204b6f77bfe70c
`))
	// }}}
	sources, err := control.ParseBinaryIndex(reader)
	isok(t, err)
	assert(t, len(sources) == 1)

	ddms := sources[0]
	ddmsDepends := ddms.GetDepends()
	assert(t, ddmsDepends.GetAllPossibilities()[0].Version.Number == "22.2+git20130830~92d25d6-1")
}

// vim: foldmethod=marker
