/*

This module provides an API to access and programmatically process
Debian `.deb` archives on disk.

Debian files, at a high level, are `ar(1)` archives, which
contain a few sections, most notably the `control` member, which contains
information about the Debian package itself, and the `data` member, which
contains the actual contents of the files, as they should be written out
on disk.

Here's a trivial example, which will print out the Package name for a
`.deb` archive given on the command line:

	package main

	import (
		"log"
		"os"

		"pault.ag/go/debian/deb"
	)

	func main() {
		path := os.Args[1]
		fd, err := os.Open(path)
		if err != nil {
			panic(err)
		}
		defer fd.Close()

		debFile, err := deb.Load(fd, path)
		if err != nil {
			panic(err)
		}
		log.Printf("Package: %s\n", debFile.Control.Package)
	}

*/
package deb
