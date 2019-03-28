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
	"errors"
	"strings"
)

/*
 */
type Arch struct {
	ABI string
	OS  string
	CPU string
}

func ParseArchitectures(arch string) ([]Arch, error) {
	ret := []Arch{}
	arches := strings.Split(arch, " ")
	for _, el := range arches {
		el := strings.Trim(el, " \t\n\r")

		if el == "" {
			continue
		}

		arch, err := ParseArch(el)
		if err != nil {
			return nil, err
		}
		ret = append(ret, *arch)
	}
	return ret, nil
}

func (arch *Arch) UnmarshalControl(data string) error {
	return parseArchInto(arch, data)
}

func ParseArch(arch string) (*Arch, error) {
	ret := &Arch{
		ABI: "any",
		OS:  "any",
		CPU: "any",
	}
	return ret, parseArchInto(ret, arch)
}

/*
 */
func parseArchInto(ret *Arch, arch string) error {
	/* May be in the following form:
	 * `any` (implicitly any-any-any)
	 * kfreebsd-any (implicitly any-kfreebsd-any)
	 * kfreebsd-amd64 (implicitly any-kfreebsd-any)
	 * bsd-openbsd-i386 */
	flavors := strings.SplitN(arch, "-", 3)
	switch len(flavors) {
	case 1:
		flavor := flavors[0]
		/* OK, we've got a single guy like `any` or `amd64` */
		switch flavor {
		case "all", "any":
			ret.ABI = flavor
			ret.OS = flavor
			ret.CPU = flavor
		default:
			/* right, so we've got something like `amd64`, which is implicitly
			 * gnu-linux-amd64. Confusing, I know. */
			ret.ABI = "gnu"
			ret.OS = "linux"
			ret.CPU = flavor
		}
	case 2:
		/* Right, this is something like kfreebsd-amd64, which is implicitly
		 * gnu-kfreebsd-amd64 */
		ret.OS = flavors[0]
		ret.CPU = flavors[1]
	case 3:
		/* This is something like bsd-openbsd-amd64 */
		ret.ABI = flavors[0]
		ret.OS = flavors[1]
		ret.CPU = flavors[2]
	default:
		return errors.New("Hurm, no idea what happened here")
	}

	return nil
}

/*
 */
func (set *ArchSet) Matches(other *Arch) bool {
	/* If [!amd64 sparc] matches gnu-linux-any */

	if len(set.Architectures) == 0 {
		/* We're not a thing. Always true. */
		return true
	}

	not := set.Not
	for _, el := range set.Architectures {
		if el.Is(other) {
			/* For each arch; check if it matches. If it does, then
			 * return true (unless we're negated) */
			return !not
		}
	}
	/* Otherwise, let's return false (unless we're negated) */
	return not
}

/*
 */
func (arch *Arch) IsWildcard() bool {
	if arch.CPU == "all" {
		return false
	}

	if arch.ABI == "any" || arch.OS == "any" || arch.CPU == "any" {
		return true
	}
	return false
}

/*
 */
func (arch *Arch) Is(other *Arch) bool {

	if arch.IsWildcard() && other.IsWildcard() {
		/* We can't compare wildcards to other wildcards. That's just
		 * insanity. We always need a concrete arch. Not even going to try. */
		return false
	} else if arch.IsWildcard() {
		/* OK, so we're a wildcard. Let's defer to the other
		 * struct to deal with this */
		return other.Is(arch)
	}

	if (arch.CPU == other.CPU || (arch.CPU != "all" && other.CPU == "any")) &&
		(arch.OS == other.OS || other.OS == "any") &&
		(arch.ABI == other.ABI || other.ABI == "any") {

		return true
	}

	return false
}

// vim: foldmethod=marker
