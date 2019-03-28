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
	"strings"
)

func (a Arch) MarshalControl() (string, error) {
	return a.String(), nil
}

func (a Arch) String() string {
	/* ABI-OS-CPU -- gnu-linux-amd64 */
	els := []string{}
	if a.ABI != "any" && a.ABI != "all" && a.ABI != "gnu" && a.ABI != "" {
		els = append(els, a.ABI)
	}

	if a.OS != "any" && a.OS != "all" && a.OS != "linux" {
		els = append(els, a.OS)
	}

	els = append(els, a.CPU)
	return strings.Join(els, "-")
}

func (set ArchSet) String() string {
	if len(set.Architectures) == 0 {
		return ""
	}
	not := ""
	if set.Not {
		not = "!"
	}
	arches := []string{}
	for _, arch := range set.Architectures {
		arches = append(arches, not+arch.String())
	}
	return "[" + strings.Join(arches, " ") + "]"
}

func (version VersionRelation) String() string {
	return "(" + version.Operator + " " + version.Number + ")"
}

func (stage Stage) String() string {
	if stage.Not {
		return "!" + stage.Name
	}
	return stage.Name
}

func (stageSet StageSet) String() string {
	if len(stageSet.Stages) == 0 {
		return ""
	}
	stages := []string{}
	for _, stage := range stageSet.Stages {
		stages = append(stages, stage.String())
	}
	return "<" + strings.Join(stages, " ") + ">"
}

func (possi Possibility) String() string {
	str := possi.Name
	if possi.Arch != nil {
		str += ":" + possi.Arch.String()
	}
	if possi.Architectures != nil {
		if arch := possi.Architectures.String(); arch != "" {
			str += " " + arch
		}
	}
	if possi.Version != nil {
		str += " " + possi.Version.String()
	}
	for _, stageSet := range possi.StageSets {
		if stages := stageSet.String(); stages != "" {
			str += " " + stages
		}
	}
	return str
}

func (relation Relation) String() string {
	possis := []string{}
	for _, possi := range relation.Possibilities {
		possis = append(possis, possi.String())
	}
	return strings.Join(possis, " | ")
}

func (dependency Dependency) String() string {
	relations := []string{}
	for _, relation := range dependency.Relations {
		relations = append(relations, relation.String())
	}
	return strings.Join(relations, ", ")
}

// vim: foldmethod=marker
