package stripper

import (
	"bufio"
	"bytes"
	"io"
	"strings"
	"unicode"
)

type CommentStripper struct {
	Comment    string
	Delimiter  byte
	Whitespace bool

	r   *bufio.Reader
	buf bytes.Buffer
}

func NewCommentStripper(r io.Reader) *CommentStripper {
	return &CommentStripper{
		Comment:    "#",
		Delimiter:  '\n',
		Whitespace: true,

		r: bufio.NewReader(r),
	}
}

func (r *CommentStripper) Read(p []byte) (int, error) {
	for {
		if r.buf.Len() >= len(p) {
			return r.buf.Read(p)
		}
		line, err := r.r.ReadString(r.Delimiter)
		if len(line) > 0 {
			checkLine := line
			if r.Whitespace {
				checkLine = strings.TrimLeftFunc(checkLine, unicode.IsSpace)
			}
			if strings.HasPrefix(checkLine, r.Comment) {
				// yay, skip this line
				continue
			}
			r.buf.WriteString(line)
		}
		if err != nil {
			if r.buf.Len() > 0 {
				return r.buf.Read(p)
			}
			return 0, err
		}
	}
}
