package stripper_test

import (
	"io"
	"os"
	"strings"

	"github.com/docker-library/go-dockerlibrary/pkg/stripper"
)

func ExampleCommentStripper() {
	r := strings.NewReader(`
# opening comment
a: b
# comment!
c: d # not a comment

# another cheeky comment
e: f
`)

	comStrip := stripper.NewCommentStripper(r)

	// using CopyBuffer to force smaller Read sizes (better testing coverage that way)
	io.CopyBuffer(os.Stdout, comStrip, make([]byte, 32))

	// Output:
	// a: b
	// c: d # not a comment
	//
	// e: f
}
