package hashio // import "pault.ag/go/debian/hashio"

import (
	"fmt"
	"io"

	"compress/gzip"
)

type Compressor func(io.Writer) (io.WriteCloser, error)

func gzipCompressor(in io.Writer) (io.WriteCloser, error) {
	return gzip.NewWriter(in), nil
}

var knownCompressors = map[string]Compressor{
	"gz": gzipCompressor,
}

func GetCompressor(name string) (Compressor, error) {
	if compressor, ok := knownCompressors[name]; ok {
		return compressor, nil
	}
	return nil, fmt.Errorf("No such compressor: '%s'", name)
}
