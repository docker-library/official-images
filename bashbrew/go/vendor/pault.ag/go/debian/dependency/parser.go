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
	"fmt"
)

// Parse a string into a Dependency object. The input should look something
// like "foo, bar | baz".
func Parse(in string) (*Dependency, error) {
	ibuf := input{Index: 0, Data: in}
	dep := &Dependency{Relations: []Relation{}}
	err := parseDependency(&ibuf, dep)
	if err != nil {
		return nil, err
	}
	return dep, nil
}

// input Model {{{

/*
 */
type input struct {
	Data  string
	Index int
}

/*
 */
func (i *input) Peek() byte {
	if (i.Index) >= len(i.Data) {
		return 0
	}
	return i.Data[i.Index]
}

/*
 */
func (i *input) Next() byte {
	chr := i.Peek()
	i.Index++
	return chr
}

// }}}

// Parse Helpers {{{

/* */
func eatWhitespace(input *input) {
	for {
		peek := input.Peek()
		switch peek {
		case '\r', '\n', ' ', '\t':
			input.Next()
			continue
		}
		break
	}
}

// }}}

// Dependency Parser {{{

/* */
func parseDependency(input *input, ret *Dependency) error {
	eatWhitespace(input)

	for {
		peek := input.Peek()
		switch peek {
		case 0: /* EOF, yay */
			return nil
		case ',': /* Next relation set */
			input.Next()
			eatWhitespace(input)
			continue
		}
		err := parseRelation(input, ret)
		if err != nil {
			return err
		}
	}
}

// }}}

// Relation Parser {{{

/* */
func parseRelation(input *input, dependency *Dependency) error {
	eatWhitespace(input) /* Clean out leading whitespace */

	ret := &Relation{Possibilities: []Possibility{}}

	for {
		peek := input.Peek()
		switch peek {
		case 0, ',': /* EOF, or done with this relation! yay */
			dependency.Relations = append(dependency.Relations, *ret)
			return nil
		case '|': /* Next Possi */
			input.Next()
			eatWhitespace(input)
			continue
		}
		err := parsePossibility(input, ret)
		if err != nil {
			return err
		}
	}
}

// }}}

// Possibility Parser {{{

/* */
func parsePossibility(input *input, relation *Relation) error {
	eatWhitespace(input) /* Clean out leading whitespace */

	peek := input.Peek()
	if peek == '$' {
		/* OK, nice. So, we've got a substvar. Let's eat it. */
		return parseSubstvar(input, relation)
	}

	/* Otherwise, let's punt and build it up ourselves. */

	ret := &Possibility{
		Name:          "",
		Version:       nil,
		Architectures: &ArchSet{Architectures: []Arch{}},
		StageSets:     []StageSet{},
		Substvar:      false,
	}

	for {
		peek := input.Peek()
		switch peek {
		case ':':
			err := parseMultiarch(input, ret)
			if err != nil {
				return err
			}
			continue
		case ' ':
			err := parsePossibilityControllers(input, ret)
			if err != nil {
				return err
			}
			continue
		case ',', '|', 0: /* I'm out! */
			if ret.Name == "" {
				return nil // e.g. trailing comma in Build-Depends
			}
			relation.Possibilities = append(relation.Possibilities, *ret)
			return nil
		}
		/* Not a control, let's append */
		ret.Name += string(input.Next())
	}
}

func parseSubstvar(input *input, relation *Relation) error {
	eatWhitespace(input)
	input.Next() /* Assert ch == '$' */
	input.Next() /* Assert ch == '{' */

	ret := &Possibility{
		Name:     "",
		Version:  nil,
		Substvar: true,
	}

	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before substvar finished")
		case '}':
			input.Next()
			relation.Possibilities = append(relation.Possibilities, *ret)
			return nil
		}
		ret.Name += string(input.Next())
	}
}

/* */
func parseMultiarch(input *input, possi *Possibility) error {
	input.Next() /* mandated to be a : */
	name := ""
	for {
		peek := input.Peek()
		switch peek {
		case ',', '|', 0, ' ', '(', '[', '<':
			arch, err := ParseArch(name)
			if err != nil {
				return err
			}
			possi.Arch = arch
			return nil
		default:
			name += string(input.Next())
		}
	}
	return nil
}

/* */
func parsePossibilityControllers(input *input, possi *Possibility) error {
	for {
		eatWhitespace(input) /* Clean out leading whitespace */
		peek := input.Peek()
		switch peek {
		case ',', '|', 0:
			return nil
		case '(':
			if possi.Version != nil {
				return errors.New(
					"Only one Version relation per Possibility, please!",
				)
			}
			err := parsePossibilityVersion(input, possi)
			if err != nil {
				return err
			}
			continue
		case '[':
			if len(possi.Architectures.Architectures) != 0 {
				return errors.New(
					"Only one Arch relation per Possibility, please!",
				)
			}
			err := parsePossibilityArchs(input, possi)
			if err != nil {
				return err
			}
			continue
		case '<':
			err := parsePossibilityStageSet(input, possi)
			if err != nil {
				return err
			}
			continue
		}
		return fmt.Errorf("Trailing garbage in a Possibility: %c", peek)
	}
	return nil
}

/* */
func parsePossibilityVersion(input *input, possi *Possibility) error {
	eatWhitespace(input)
	input.Next() /* mandated to be ( */
	// assert ch == '('
	version := VersionRelation{}

	err := parsePossibilityOperator(input, &version)
	if err != nil {
		return err
	}

	err = parsePossibilityNumber(input, &version)
	if err != nil {
		return err
	}

	input.Next() /* OK, let's tidy up */
	// assert ch == ')'

	possi.Version = &version
	return nil
}

/* */
func parsePossibilityOperator(input *input, version *VersionRelation) error {
	eatWhitespace(input)
	leader := input.Next() /* may be 0 */

	if leader == '=' {
		/* Great, good enough. */
		version.Operator = "="
		return nil
	}

	/* This is always one of:
	 * >=, <=, <<, >> */
	secondary := input.Next()
	if leader == 0 || secondary == 0 {
		return errors.New("Oh no. Reached EOF before Operator finished")
	}

	operator := string([]rune{rune(leader), rune(secondary)})

	switch operator {
	case ">=", "<=", "<<", ">>":
		version.Operator = operator
		return nil
	}

	return fmt.Errorf(
		"Unknown Operator in Possibility Version modifier: %s",
		operator,
	)

}

/* */
func parsePossibilityNumber(input *input, version *VersionRelation) error {
	eatWhitespace(input)
	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before Number finished")
		case ')':
			return nil
		}
		version.Number += string(input.Next())
	}
}

/* */
func parsePossibilityArchs(input *input, possi *Possibility) error {
	eatWhitespace(input)
	input.Next() /* Assert ch == '[' */

	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before Arch list finished")
		case ']':
			input.Next()
			return nil
		}

		err := parsePossibilityArch(input, possi)
		if err != nil {
			return err
		}
	}
}

/* */
func parsePossibilityArch(input *input, possi *Possibility) error {
	eatWhitespace(input)
	arch := ""

	// Exclamation marks may be prepended to each of the names. (It is not
	// permitted for some names to be prepended with exclamation marks while
	// others aren't.)
	hasNot := input.Peek() == '!'
	if hasNot {
		input.Next() // '!'
	}
	if len(possi.Architectures.Architectures) == 0 {
		possi.Architectures.Not = hasNot
	} else if possi.Architectures.Not != hasNot {
		return errors.New("Either the entire arch list needs negations, or none of it does -- no mix and match :/")
	}

	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before Arch list finished")
		case '!':
			return errors.New("You can only negate whole blocks :(")
		case ']', ' ': /* Let our parent deal with both of these */
			archObj, err := ParseArch(arch)
			if err != nil {
				return err
			}
			possi.Architectures.Architectures = append(
				possi.Architectures.Architectures,
				*archObj,
			)
			return nil
		}
		arch += string(input.Next())
	}
}

/* */
func parsePossibilityStageSet(input *input, possi *Possibility) error {
	eatWhitespace(input)
	input.Next() /* Assert ch == '<' */

	stageSet := StageSet{}
	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before StageSet finished")
		case '>':
			input.Next()
			possi.StageSets = append(possi.StageSets, stageSet)
			return nil
		}

		err := parsePossibilityStage(input, &stageSet)
		if err != nil {
			return err
		}
	}
}

/* */
func parsePossibilityStage(input *input, stageSet *StageSet) error {
	eatWhitespace(input)

	stage := Stage{}
	for {
		peek := input.Peek()
		switch peek {
		case 0:
			return errors.New("Oh no. Reached EOF before Stage finished")
		case '!':
			input.Next()
			if stage.Not {
				return errors.New("Double-negation (!!) of a single Stage is not permitted :(")
			}
			stage.Not = !stage.Not
		case '>', ' ': /* Let our parent deal with both of these */
			stageSet.Stages = append(stageSet.Stages, stage)
			return nil
		}
		stage.Name += string(input.Next())
	}
}

// }}}

// vim: foldmethod=marker
