package hashio // import "pault.ag/go/debian/hashio"

import (
	"io"
)

func NewHasherWriter(hash string, target io.Writer) (io.Writer, *Hasher, error) {
	hw, err := NewHasher(hash)
	if err != nil {
		return nil, nil, err
	}
	endWriter := io.MultiWriter(target, hw)
	return endWriter, hw, nil
}

func NewHasherWriters(hashes []string, target io.Writer) (io.Writer, []*Hasher, error) {
	hashers := []*Hasher{}
	writers := []io.Writer{}

	for _, hash := range hashes {
		hw, err := NewHasher(hash)
		if err != nil {
			return nil, nil, err
		}
		hashers = append(hashers, hw)
		writers = append(writers, hw)
	}

	endWriter := io.MultiWriter(append(writers, target)...)
	return endWriter, hashers, nil
}

func NewHasherReader(hash string, target io.Reader) (io.Reader, *Hasher, error) {
	hw, err := NewHasher(hash)
	if err != nil {
		return nil, nil, err
	}
	endReader := io.TeeReader(target, hw)
	return endReader, hw, nil
}

func NewHasherReaders(hashes []string, target io.Reader) (io.Reader, []*Hasher, error) {
	hashers := []*Hasher{}
	writers := []io.Writer{}

	for _, hash := range hashes {
		hw, err := NewHasher(hash)
		if err != nil {
			return nil, nil, err
		}
		hashers = append(hashers, hw)
		writers = append(writers, hw)
	}
	endReader := io.TeeReader(target, io.MultiWriter(writers...))
	return endReader, hashers, nil
}
