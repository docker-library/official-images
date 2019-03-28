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

package dependency // import "pault.ag/go/debian/dependency"

import (
	"pault.ag/go/debian/version"
)

//
func (dep *Dependency) GetPossibilities(arch Arch) []Possibility {
	possies := []Possibility{}

	for _, relation := range dep.Relations {
		for _, possibility := range relation.Possibilities {
			if possibility.Substvar {
				continue
			}

			if possibility.Architectures.Matches(&arch) {
				possies = append(possies, possibility)
				break
			}
		}
	}

	return possies
}

//
func (dep *Dependency) GetAllPossibilities() []Possibility {
	possies := []Possibility{}

	for _, relation := range dep.Relations {
		for _, possibility := range relation.Possibilities {
			if possibility.Substvar {
				continue
			}
			possies = append(possies, possibility)
		}
	}

	return possies
}

//
func (dep *Dependency) GetSubstvars() []Possibility {
	possies := []Possibility{}

	for _, relation := range dep.Relations {
		for _, possibility := range relation.Possibilities {
			if possibility.Substvar {
				possies = append(possies, possibility)
			}
		}
	}

	return possies
}

func (v VersionRelation) SatisfiedBy(ver version.Version) bool {
	vVer, err := version.Parse(v.Number)
	if err != nil {
		return false
	}

	q := version.Compare(ver, vVer)
	switch v.Operator {
	case ">=":
		return q >= 0
	case "<=":
		return q <= 0
	case ">>":
		return q > 0
	case "<<":
		return q < 0
	case "=":
		return q == 0
	}

	// XXX: WHAT THE SHIT
	return false
}

// vim: foldmethod=marker
