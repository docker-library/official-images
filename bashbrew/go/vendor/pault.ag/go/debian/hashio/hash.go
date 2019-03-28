package hashio // import "pault.ag/go/debian/hashio"

import (
	"fmt"
	"hash"

	"crypto/md5"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
)

func GetHash(name string) (hash.Hash, error) {
	switch name {
	case "md5":
		return md5.New(), nil
	case "sha1":
		return sha1.New(), nil
	case "sha256":
		return sha256.New(), nil
	case "sha512":
		return sha512.New(), nil
	default:
		return nil, fmt.Errorf("Unknown algorithm: %s", name)
	}
}

func NewHasher(name string) (*Hasher, error) {
	hash, err := GetHash(name)
	if err != nil {
		return nil, err
	}

	hw := Hasher{
		name: name,
		hash: hash,
		size: 0,
	}

	return &hw, nil
}

type Hasher struct {
	name string
	hash hash.Hash
	size int64
}

func (dh *Hasher) Name() string {
	return dh.name
}

func (dh *Hasher) Write(p []byte) (int, error) {
	n, err := dh.hash.Write(p)
	dh.size += int64(n)
	return n, err
}

func (dh *Hasher) Size() int64 {
	return dh.size
}

func (dh *Hasher) Sum(b []byte) []byte {
	return dh.hash.Sum(b)
}
