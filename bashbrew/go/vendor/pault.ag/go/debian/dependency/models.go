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

// Possibilities {{{

// Arch models an architecture dependency restriction, commonly used to
// restrict the relation to one some architectures. This is also usually
// used in a string of many possibilities.
type ArchSet struct {
	Not           bool
	Architectures []Arch
}

// VersionRelation models a version restriction on a possibility, such as
// greater than version 1.0, or less than 2.0. The values that are valid
// in the Operator field are defined by section 7.1 of Debian policy.
//
//   The relations allowed are <<, <=, =, >= and >> for strictly earlier,
//   earlier or equal, exactly equal, later or equal and strictly later,
//   respectively.
//
type VersionRelation struct {
	Number   string
	Operator string
}

type Stage struct {
	Not  bool
	Name string
}

type StageSet struct {
	Stages []Stage
}

// Possibility models a concrete Possibility that may be satisfied in order
// to satisfy the Dependency Relation. Given the Dependency line:
//
//   Depends: foo, bar | baz
//
// All of foo, bar and baz are Possibilities. Possibilities may come with
// further restrictions, such as restrictions on Version, Architecture, or
// Build Stage.
//
type Possibility struct {
	Name          string
	Arch          *Arch
	Architectures *ArchSet
	StageSets     []StageSet
	Version       *VersionRelation
	Substvar      bool
}

// }}}

// A Relation is a set of Possibilities that must be satisfied. Given the
// Dependency line:
//
//   Depends: foo, bar | baz
//
// There are two Relations, one composed of foo, and another composed of
// bar and baz.
type Relation struct {
	Possibilities []Possibility
}

// A Dependency is the top level type that models a full Dependency relation.
type Dependency struct {
	Relations []Relation
}

func (dep *Dependency) UnmarshalControl(data string) error {
	ibuf := input{Index: 0, Data: data}
	dep.Relations = []Relation{}
	err := parseDependency(&ibuf, dep)
	return err
}

func (dep Dependency) MarshalControl() (string, error) {
	return dep.String(), nil
}

// vim: foldmethod=marker
