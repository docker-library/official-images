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
	"io"
	"log"
	"strings"
	"testing"

	"golang.org/x/crypto/openpgp"
	"pault.ag/go/debian/control"
)

/*
 *
 */

// Signed Paragraph {{{
const signedParagraph = `-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.8
Date: Mon, 16 Nov 2015 21:15:55 -0800
Source: hy
Binary: hy python-hy python3-hy
Architecture: source
Version: 0.11.0-4
Distribution: unstable
Urgency: medium
Maintainer: Tianon Gravi <tianon@debian.org>
Changed-By: Tianon Gravi <tianon@debian.org>
Description:
 hy         - Lisp (s-expression) based frontend to Python (metapackage)
 python-hy  - Lisp (s-expression) based frontend to Python
 python3-hy - Lisp (s-expression) based frontend to Python 3
Closes: 805204
Changes:
 hy (0.11.0-4) unstable; urgency=medium
 .
   * Fix FTBFS due to rply trying to write to HOME during sphinx-build.
   * Fix build repeatability with proper override_dh_auto_clean.
   * Fix FTBFS now that the tests actually run (Closes: #805204).
   * Add "hyc" and "hy2py" as slaves to the "hy" alternative.
   * Add alternatives to python-hy package also (to make testing easier).
Checksums-Sha1:
 cbb00b96ba8ad4f27f8f6f6ceb626f0857c1d985 2170 hy_0.11.0-4.dsc
 802ebce0dc09000a243cf809c922d5f0e1af90f0 7536 hy_0.11.0-4.debian.tar.xz
Checksums-Sha256:
 2c91c414f8c7a0556372c94301b8786801a05b29aafeceb2e308e037d47d5ddc 2170 hy_0.11.0-4.dsc
 27610d4e31645bc888c633881082270917aedd3443e36031a0030d3dae6f7380 7536 hy_0.11.0-4.debian.tar.xz
Files:
 42d61a06f37db6f2d2fc6c35b2d4e683 2170 python optional hy_0.11.0-4.dsc
 aa8bfae41ef33a85e0f08f21e0a5e67b 7536 python optional hy_0.11.0-4.debian.tar.xz

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQIcBAEBCgAGBQJWSrgkAAoJEANqnCW/NX3UEjQP/ikiMZWvhco6jz9ObT/Q1FbK
fjoaZbOBLAoP/kBD4m9s/GiBNb0mHAtn3186uh5ZbXw7NEz9hfQeNAL2qHOqYsT3
7Ha31kwjV9ZfSLbu6giCImoBPBV6kqn904QVjHiSJ/d08PdEgDPcOrDYUBPYH+O0
BmHDlWb9mBRIMIjXl6HtZIMvJ1adU613h3T6C4VMExV1YRGaD4UlUxUkfdKMZ0kx
GUNsyARKxXbMMr9uqnmDp3K85U6BynOiZ8aLnzWjVKDpXPQOK/3n4sfN6iNJF+9K
nl26axBfgoj/kvNLXGOR+rpGz0IBE7QpecVh7eFUb87i4En+lZi9pl0+hC/2n+Xy
vShNXphZZQ444P5CMX5s8OK0IbWl1wVe0OCjcQhW9juOIGdn3bxWJ68HaIbw5Y+V
TZcmHxjJJbO+D+ng3OHqCg1tooy1dAeMZlRwsgYyDtx0Rhd7gZKzx5NkuWlBOdSH
P+FikrKFHW6rvvO0esWqgm7GuBDrMrsPgU9T4UZ1sOOwsBdWTgp9QWceFIrrptX0
C/hiBXZkJP/cXueZQ38GDny6ahuR5HDmNwHhvV/EuZ28GOdKzCxcOCyhoNI2xgOg
A8Ija2WnFdScMVRuMxDxK8yMdy1/BtZQKV6uzSt7ebHfPcUopBM4yARM8C90EbJD
/FevdZ9cGw/0bCyun86t
=dtCZ
-----END PGP SIGNATURE-----
`

// }}}

func isok(t *testing.T, err error) {
	if err != nil && err != io.EOF {
		log.Printf("Error! Error is not nil! - %s\n", err)
		t.FailNow()
	}
}

func notok(t *testing.T, err error) {
	if err == nil {
		log.Printf("Error! Error is nil!\n")
		t.FailNow()
	}
}

func assert(t *testing.T, expr bool) {
	if !expr {
		log.Printf("Assertion failed!")
		t.FailNow()
	}
}

/*
 *
 */

func TestBasicParagraphReader(t *testing.T) {
	// Reader {{{
	reader, err := control.NewParagraphReader(strings.NewReader(`Para: one

Para: two

Para: three
`), nil)
	// }}}
	isok(t, err)

	blocks, err := reader.All()
	isok(t, err)
	assert(t, len(blocks) == 3)
}

func TestOpenPGPParagraphReader(t *testing.T) {
	reader, err := control.NewParagraphReader(strings.NewReader(signedParagraph), nil)
	isok(t, err)

	blocks, err := reader.All()
	isok(t, err)
	assert(t, len(blocks) == 1)
}

func TestEmptyKeyringOpenPGPParagraphReader(t *testing.T) {
	keyring := openpgp.EntityList{}

	// Reader {{{
	_, err := control.NewParagraphReader(strings.NewReader(`-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 1.8
Date: Mon, 16 Nov 2015 21:15:55 -0800
Source: hy
Binary: hy python-hy python3-hy
Architecture: source
Version: 0.11.0-4
Distribution: unstable
Urgency: medium
Maintainer: Tianon Gravi <tianon@debian.org>
Changed-By: Tianon Gravi <tianon@debian.org>
Description:
 hy         - Lisp (s-expression) based frontend to Python (metapackage)
 python-hy  - Lisp (s-expression) based frontend to Python
 python3-hy - Lisp (s-expression) based frontend to Python 3
Closes: 805204
Changes:
 hy (0.11.0-4) unstable; urgency=medium
 .
   * Fix FTBFS due to rply trying to write to HOME during sphinx-build.
   * Fix build repeatability with proper override_dh_auto_clean.
   * Fix FTBFS now that the tests actually run (Closes: #805204).
   * Add "hyc" and "hy2py" as slaves to the "hy" alternative.
   * Add alternatives to python-hy package also (to make testing easier).
Checksums-Sha1:
 cbb00b96ba8ad4f27f8f6f6ceb626f0857c1d985 2170 hy_0.11.0-4.dsc
 802ebce0dc09000a243cf809c922d5f0e1af90f0 7536 hy_0.11.0-4.debian.tar.xz
Checksums-Sha256:
 2c91c414f8c7a0556372c94301b8786801a05b29aafeceb2e308e037d47d5ddc 2170 hy_0.11.0-4.dsc
 27610d4e31645bc888c633881082270917aedd3443e36031a0030d3dae6f7380 7536 hy_0.11.0-4.debian.tar.xz
Files:
 42d61a06f37db6f2d2fc6c35b2d4e683 2170 python optional hy_0.11.0-4.dsc
 aa8bfae41ef33a85e0f08f21e0a5e67b 7536 python optional hy_0.11.0-4.debian.tar.xz

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1

iQIcBAEBCgAGBQJWSrgkAAoJEANqnCW/NX3UEjQP/ikiMZWvhco6jz9ObT/Q1FbK
fjoaZbOBLAoP/kBD4m9s/GiBNb0mHAtn3186uh5ZbXw7NEz9hfQeNAL2qHOqYsT3
7Ha31kwjV9ZfSLbu6giCImoBPBV6kqn904QVjHiSJ/d08PdEgDPcOrDYUBPYH+O0
BmHDlWb9mBRIMIjXl6HtZIMvJ1adU613h3T6C4VMExV1YRGaD4UlUxUkfdKMZ0kx
GUNsyARKxXbMMr9uqnmDp3K85U6BynOiZ8aLnzWjVKDpXPQOK/3n4sfN6iNJF+9K
nl26axBfgoj/kvNLXGOR+rpGz0IBE7QpecVh7eFUb87i4En+lZi9pl0+hC/2n+Xy
vShNXphZZQ444P5CMX5s8OK0IbWl1wVe0OCjcQhW9juOIGdn3bxWJ68HaIbw5Y+V
TZcmHxjJJbO+D+ng3OHqCg1tooy1dAeMZlRwsgYyDtx0Rhd7gZKzx5NkuWlBOdSH
P+FikrKFHW6rvvO0esWqgm7GuBDrMrsPgU9T4UZ1sOOwsBdWTgp9QWceFIrrptX0
C/hiBXZkJP/cXueZQ38GDny6ahuR5HDmNwHhvV/EuZ28GOdKzCxcOCyhoNI2xgOg
A8Ija2WnFdScMVRuMxDxK8yMdy1/BtZQKV6uzSt7ebHfPcUopBM4yARM8C90EbJD
/FevdZ9cGw/0bCyun86t
=dtCZ
-----END PGP SIGNATURE-----
`), &keyring)
	// }}}
	notok(t, err)
}

func TestLineWrapping(t *testing.T) {
	reader, err := control.NewParagraphReader(strings.NewReader(signedParagraph), nil)
	isok(t, err)

	el, err := reader.Next()
	isok(t, err)

	assert(t, el.Values["Changes"] == `hy (0.11.0-4) unstable; urgency=medium

  * Fix FTBFS due to rply trying to write to HOME during sphinx-build.
  * Fix build repeatability with proper override_dh_auto_clean.
  * Fix FTBFS now that the tests actually run (Closes: #805204).
  * Add "hyc" and "hy2py" as slaves to the "hy" alternative.
  * Add alternatives to python-hy package also (to make testing easier).
`)
}

// vim: foldmethod=marker
