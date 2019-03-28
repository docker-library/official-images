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

package control // import "pault.ag/go/debian/control"

import (
	"fmt"
	"io"
	"reflect"
	"strconv"
	"strings"

	"golang.org/x/crypto/openpgp"
)

// Unmarshallable {{{

// The Unmarshallable interface defines the interface that Unmarshal will use
// to do custom unpacks into Structs.
//
// The argument passed in will be a string that contains the value of the
// RFC822 key this object relates to.
type Unmarshallable interface {
	UnmarshalControl(data string) error
}

// }}}

// Unmarshal {{{

// Given a struct (or list of structs), read the io.Reader RFC822-alike
// Debian control-file stream into the struct, unpacking keys into the
// struct as needed. If a list of structs is given, unpack all RFC822
// Paragraphs into the structs.
//
// This code will attempt to unpack it into the struct based on the
// literal name of the key, compared byte-for-byte. If this is not
// OK, the struct tag `control:""` can be used to define the key to use
// in the RFC822 stream.
//
// If you're unpacking into a list of strings, you have the option of defining
// a string to split tokens on (`delim:", "`), and things to strip off each
// element (`strip:"\n\r\t "`).
//
// If you're unpacking into a struct, the struct will be walked according to
// the rules above. If you wish to override how this writes to the nested
// struct, objects that implement the Unmarshallable interface will be
// Unmarshaled via that method call only.
//
// Structs that contain Paragraph as an Anonymous member will have that
// member populated with the parsed RFC822 block, to allow access to the
// .Values and .Order members.
func Unmarshal(data interface{}, reader io.Reader) error {
	decoder, err := NewDecoder(reader, nil)
	if err != nil {
		return err
	}
	return decoder.Decode(data)
}

// }}}

// Decoder {{{

type Decoder struct {
	paragraphReader ParagraphReader
}

// NewDecoder {{{

func NewDecoder(reader io.Reader, keyring *openpgp.EntityList) (*Decoder, error) {
	ret := Decoder{}
	pr, err := NewParagraphReader(reader, keyring)
	if err != nil {
		return nil, err
	}
	ret.paragraphReader = *pr
	return &ret, nil
}

// }}}

// Decode {{{

func (d *Decoder) Decode(into interface{}) error {
	return decode(&d.paragraphReader, reflect.ValueOf(into))
}

// Top-level decode dispatch {{{

func decode(p *ParagraphReader, into reflect.Value) error {
	if into.Type().Kind() != reflect.Ptr {
		return fmt.Errorf("Decode can only decode into a pointer!")
	}

	switch into.Elem().Type().Kind() {
	case reflect.Struct:
		paragraph, err := p.Next()
		if err != nil {
			return err
		}
		return decodeStruct(*paragraph, into)
	case reflect.Slice:
		return decodeSlice(p, into)
	default:
		return fmt.Errorf("Can't Decode into a %s", into.Elem().Type().Name())
	}

	return nil
}

// }}}

// Top-level struct dispatch {{{

func decodeStruct(p Paragraph, into reflect.Value) error {
	/* If we have a pointer, let's follow it */
	if into.Type().Kind() == reflect.Ptr {
		return decodeStruct(p, into.Elem())
	}

	/* Store the Paragraph type for later use when checking Anonymous
	 * values. */
	paragraphType := reflect.TypeOf(Paragraph{})

	/* Right, now, we're going to decode a Paragraph into the struct */

	for i := 0; i < into.NumField(); i++ {
		field := into.Field(i)
		fieldType := into.Type().Field(i)

		if field.Type().Kind() == reflect.Struct {
			err := decodeStruct(p, field)
			if err != nil {
				return err
			}
		}

		/* First, let's get the name of the field as we'd index into the
		 * map[string]string. */
		paragraphKey := fieldType.Name
		if it := fieldType.Tag.Get("control"); it != "" {
			paragraphKey = it
		}

		if paragraphKey == "-" {
			/* If the key is "-", lets go ahead and skip it */
			continue
		}

		/* Now, if we have an Anonymous field, we're either going to
		 * set it to the Paragraph if it's the Paragraph Anonymous member,
		 * or, more likely, continue through */
		if fieldType.Anonymous {
			if fieldType.Type == paragraphType {
				/* Neat! Let's give the struct this data */
				field.Set(reflect.ValueOf(p))
			} else {
				/* Otherwise, we're going to avoid doing more maths on it */
				continue
			}
		}

		if value, ok := p.Values[paragraphKey]; ok {
			if err := decodeStructValue(field, fieldType, value); err != nil {
				return err
			}
			continue
		} else {
			if fieldType.Tag.Get("required") == "true" {
				return fmt.Errorf(
					"Required field '%s' is missing!",
					fieldType.Name,
				)
			}
			continue
		}
	}

	return nil
}

// }}}

// set a struct field value {{{

func decodeStructValue(field reflect.Value, fieldType reflect.StructField, value string) error {
	switch field.Type().Kind() {
	case reflect.String:
		field.SetString(value)
		return nil
	case reflect.Int:
		if value == "" {
			field.SetInt(0)
			return nil
		}
		value, err := strconv.Atoi(value)
		if err != nil {
			return err
		}
		field.SetInt(int64(value))
		return nil
	case reflect.Slice:
		return decodeStructValueSlice(field, fieldType, value)
	case reflect.Struct:
		return decodeStructValueStruct(field, fieldType, value)
	case reflect.Bool:
		field.SetBool(value == "yes")
		return nil
	}

	return fmt.Errorf("Unknown type of field: %s", field.Type())

}

// }}}

// set a struct field value of type struct {{{

func decodeStructValueStruct(incoming reflect.Value, incomingField reflect.StructField, data string) error {
	/* Right, so, we've got a type we don't know what to do with. We should
	 * grab the method, or throw a shitfit. */
	elem := incoming.Addr()

	if unmarshal, ok := elem.Interface().(Unmarshallable); ok {
		return unmarshal.UnmarshalControl(data)
	}

	return fmt.Errorf(
		"Type '%s' does not implement control.Unmarshallable",
		incomingField.Type.Name(),
	)
}

// }}}

// set a struct field value of type slice {{{

func decodeStructValueSlice(field reflect.Value, fieldType reflect.StructField, value string) error {
	underlyingType := field.Type().Elem()

	var delim = " "
	if it := fieldType.Tag.Get("delim"); it != "" {
		delim = it
	}

	var strip = ""
	if it := fieldType.Tag.Get("strip"); it != "" {
		strip = it
	}

	value = strings.Trim(value, strip)

	for _, el := range strings.Split(value, delim) {
		el = strings.Trim(el, strip)

		targetValue := reflect.New(underlyingType)
		err := decodeStructValue(targetValue.Elem(), fieldType, el)
		if err != nil {
			return err
		}
		field.Set(reflect.Append(field, targetValue.Elem()))
	}

	return nil
}

// }}}

// Top-level slice dispatch {{{

func decodeSlice(p *ParagraphReader, into reflect.Value) error {
	flavor := into.Elem().Type().Elem()

	for {
		targetValue := reflect.New(flavor)

		/* Get a Paragraph */
		para, err := p.Next()
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		if err := decodeStruct(*para, targetValue); err != nil {
			return err
		}
		into.Elem().Set(reflect.Append(into.Elem(), targetValue.Elem()))
	}
	return nil

}

// }}}

// }}}

// Signer {{{

func (d *Decoder) Signer() *openpgp.Entity {
	return d.paragraphReader.Signer()
}

// }}}

// }}}

// UnpackFromParagraph {{{

// Unpack a Paragraph into a Struct, as if that data had been unpacked into
// that struct to begin with. The normal rules from running the Unmarshal
// API directly apply when unpacking a Paragraph using UnpackFromParagraph.
//
// In most cases, the Unmarshal API should be sufficient. Use of this API
// is mildly discouraged.
func UnpackFromParagraph(para Paragraph, incoming interface{}) error {
	data := reflect.ValueOf(incoming)
	if data.Type().Kind() != reflect.Ptr {
		return fmt.Errorf("Can only Decode a pointer to a Struct")
	}
	return decodeStruct(para, data.Elem())
}

// }}}

// vim: foldmethod=marker
