package manifest

import (
	"bytes"
	"fmt"
	"io"
)

// try parsing as a 2822 manifest, but fallback to line-based if that fails
func Parse(reader io.Reader) (*Manifest2822, error) {
	buf := &bytes.Buffer{}

	// try parsing as 2822, but also copy back into a new buffer so that if it fails, we can re-parse as line-based
	manifest, err2822 := Parse2822(io.TeeReader(reader, buf))
	if err2822 != nil {
		manifest, err := ParseLineBased(buf)
		if err != nil {
			return nil, fmt.Errorf("cannot parse manifest in either format:\nRFC 2822 error: %v\nLine-based error: %v", err2822, err)
		}
		return manifest, nil
	}

	return manifest, nil
}
