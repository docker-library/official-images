<!--

********************************************************************************

WARNING:

    DO NOT EDIT "busybox/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "busybox/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Docker Community](https://github.com/docker-library/busybox)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`1.38.0-glibc`, `1.38-glibc`, `1-glibc`, `unstable-glibc`, `glibc`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest/glibc/amd64/index.json)

-	[`1.38.0-uclibc`, `1.38-uclibc`, `1-uclibc`, `unstable-uclibc`, `uclibc`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest/uclibc/amd64/index.json)

-	[`1.38.0-musl`, `1.38-musl`, `1-musl`, `unstable-musl`, `musl`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest/musl/amd64/index.json)

-	[`1.38.0`, `1.38`, `1`, `unstable`, `latest`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest/glibc/amd64/index.json)

-	[`1.37.0-glibc`, `1.37-glibc`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest-1/glibc/amd64/index.json)

-	[`1.37.0-uclibc`, `1.37-uclibc`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest-1/uclibc/amd64/index.json)

-	[`1.37.0-musl`, `1.37-musl`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest-1/musl/amd64/index.json)

-	[`1.37.0`, `1.37`](https://github.com/docker-library/busybox/blob/70ce0fb98bee360bbcce132660d727bf6ce55a99/latest-1/glibc/amd64/index.json)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/busybox/issues](https://github.com/docker-library/busybox/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/busybox/), [`arm32v5`](https://hub.docker.com/r/arm32v5/busybox/), [`arm32v6`](https://hub.docker.com/r/arm32v6/busybox/), [`arm32v7`](https://hub.docker.com/r/arm32v7/busybox/), [`arm64v8`](https://hub.docker.com/r/arm64v8/busybox/), [`i386`](https://hub.docker.com/r/i386/busybox/), [`ppc64le`](https://hub.docker.com/r/ppc64le/busybox/), [`riscv64`](https://hub.docker.com/r/riscv64/busybox/), [`s390x`](https://hub.docker.com/r/s390x/busybox/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/busybox/` directory](https://github.com/docker-library/repo-info/blob/master/repos/busybox) ([history](https://github.com/docker-library/repo-info/commits/master/repos/busybox))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/busybox` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fbusybox)  
	[official-images repo's `library/busybox` file](https://github.com/docker-library/official-images/blob/master/library/busybox) ([history](https://github.com/docker-library/official-images/commits/master/library/busybox))

-	**Source of this description**:  
	[docs repo's `busybox/` directory](https://github.com/docker-library/docs/tree/master/busybox) ([history](https://github.com/docker-library/docs/commits/master/busybox))

# What is BusyBox? The Swiss Army Knife of Embedded Linux

Coming in somewhere between 1 and 5 Mb in on-disk size (depending on the variant), [BusyBox](http://www.busybox.net/) is a very good ingredient to craft space-efficient distributions.

BusyBox combines tiny versions of many common UNIX utilities into a single small executable. It provides replacements for most of the utilities you usually find in GNU fileutils, shellutils, etc. The utilities in BusyBox generally have fewer options than their full-featured GNU cousins; however, the options that are included provide the expected functionality and behave very much like their GNU counterparts. BusyBox provides a fairly complete environment for any small or embedded system.

> [wikipedia.org/wiki/BusyBox](https://en.wikipedia.org/wiki/BusyBox)

![logo](https://raw.githubusercontent.com/docker-library/docs/cc5d5e47fd7e0c57c9b8de4c1bfb6258e0dac85d/busybox/logo.png)

# How to use this image

## Run BusyBox shell

```console
$ docker run -it --rm busybox
```

This will drop you into an `sh` shell to allow you to do what you want inside a BusyBox system.

## Create a `Dockerfile` for a binary

```dockerfile
FROM busybox
COPY ./my-static-binary /my-static-binary
CMD ["/my-static-binary"]
```

This `Dockerfile` will allow you to create a minimal image for your statically compiled binary. You will have to compile the binary in some other place like another container. For a simpler alternative that's similarly tiny but easier to extend, [see `alpine`](https://hub.docker.com/_/alpine/).

# Image Variants

The `busybox` images contain BusyBox built against various "libc" variants (for a comparison of "libc" variants, [Eta Labs has a very nice chart](http://www.etalabs.net/compare_libcs.html) which lists many similarities and differences).

For more information about the specific particulars of the build process for each variant, see `Dockerfile.builder` in the same directory as each variant's `Dockerfile` (see links above).

## `busybox:glibc`

-	[glibc from Debian](https://packages.debian.org/search?searchon=names&exact=1&suite=all&section=all&keywords=libc6) (which is then included in the image)

## `busybox:uclibc`

-	[uClibc](https://uclibc.org) via [Buildroot](https://buildroot.org) (statically compiled)

## `busybox:musl`

-	[musl from Alpine](https://pkgs.alpinelinux.org/packages?name=musl) (statically compiled)

# License

View [license information](http://www.busybox.net/license.html) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `busybox/` directory](https://github.com/docker-library/repo-info/tree/master/repos/busybox).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
