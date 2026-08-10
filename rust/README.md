<!--

********************************************************************************

WARNING:

    DO NOT EDIT "rust/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "rust/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Rust Project developers](https://github.com/rust-lang/docker-rust)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`1-bullseye`, `1.97-bullseye`, `1.97.1-bullseye`, `bullseye`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/bullseye/Dockerfile)

-	[`1-slim-bullseye`, `1.97-slim-bullseye`, `1.97.1-slim-bullseye`, `slim-bullseye`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/bullseye/slim/Dockerfile)

-	[`1-bookworm`, `1.97-bookworm`, `1.97.1-bookworm`, `bookworm`](https://github.com/rust-lang/docker-rust/blob/5ba8fc7544e1880d0fc5f56e9f11081082057dc2/stable/bookworm/Dockerfile)

-	[`1-slim-bookworm`, `1.97-slim-bookworm`, `1.97.1-slim-bookworm`, `slim-bookworm`](https://github.com/rust-lang/docker-rust/blob/5ba8fc7544e1880d0fc5f56e9f11081082057dc2/stable/bookworm/slim/Dockerfile)

-	[`1-trixie`, `1.97-trixie`, `1.97.1-trixie`, `trixie`, `1`, `1.97`, `1.97.1`, `latest`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/trixie/Dockerfile)

-	[`1-slim-trixie`, `1.97-slim-trixie`, `1.97.1-slim-trixie`, `slim-trixie`, `1-slim`, `1.97-slim`, `1.97.1-slim`, `slim`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/trixie/slim/Dockerfile)

-	[`1-alpine3.21`, `1.97-alpine3.21`, `1.97.1-alpine3.21`, `alpine3.21`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/alpine3.21/Dockerfile)

-	[`1-alpine3.22`, `1.97-alpine3.22`, `1.97.1-alpine3.22`, `alpine3.22`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/alpine3.22/Dockerfile)

-	[`1-alpine3.23`, `1.97-alpine3.23`, `1.97.1-alpine3.23`, `alpine3.23`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/alpine3.23/Dockerfile)

-	[`1-alpine3.24`, `1.97-alpine3.24`, `1.97.1-alpine3.24`, `alpine3.24`, `1-alpine`, `1.97-alpine`, `1.97.1-alpine`, `alpine`](https://github.com/rust-lang/docker-rust/blob/40acf7919e2e27dc706918e42758a6f1c21e806b/stable/alpine3.24/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/rust-lang/docker-rust/issues](https://github.com/rust-lang/docker-rust/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/rust/), [`arm32v7`](https://hub.docker.com/r/arm32v7/rust/), [`arm64v8`](https://hub.docker.com/r/arm64v8/rust/), [`i386`](https://hub.docker.com/r/i386/rust/), [`ppc64le`](https://hub.docker.com/r/ppc64le/rust/), [`riscv64`](https://hub.docker.com/r/riscv64/rust/), [`s390x`](https://hub.docker.com/r/s390x/rust/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/rust/` directory](https://github.com/docker-library/repo-info/blob/master/repos/rust) ([history](https://github.com/docker-library/repo-info/commits/master/repos/rust))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/rust` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Frust)  
	[official-images repo's `library/rust` file](https://github.com/docker-library/official-images/blob/master/library/rust) ([history](https://github.com/docker-library/official-images/commits/master/library/rust))

-	**Source of this description**:  
	[docs repo's `rust/` directory](https://github.com/docker-library/docs/tree/master/rust) ([history](https://github.com/docker-library/docs/commits/master/rust))

# What is Rust?

Rust is a systems programming language sponsored by Mozilla Research. It is designed to be a "safe, concurrent, practical language", supporting functional and imperative-procedural paradigms. Rust is syntactically similar to C++, but is designed for better memory safety while maintaining performance.

> [wikipedia.org/wiki/Rust_(programming_language)](https://en.wikipedia.org/wiki/Rust_%28programming_language%29)

![logo](https://raw.githubusercontent.com/docker-library/docs/a11c341c57de07fbccfed7b21ea92d4bc40130a2/rust/logo.png)

# How to use this image

## Start a Rust instance running your app

The most straightforward way to use this image is to use a Rust container as both the build and runtime environment. In your `Dockerfile`, writing something along the lines of the following will compile and run your project:

```dockerfile
FROM rust:1.67

WORKDIR /usr/src/myapp
COPY . .

RUN cargo install --path .

CMD ["myapp"]
```

Then, build and run the Docker image:

```console
$ docker build -t my-rust-app .
$ docker run -it --rm --name my-running-app my-rust-app
```

This creates an image that has all of the rust tooling for the image, which is 1.8gb. If you just want the compiled application:

```dockerfile
FROM rust:1.67 as builder
WORKDIR /usr/src/myapp
COPY . .
RUN cargo install --path .

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y extra-runtime-dependencies && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/cargo/bin/myapp /usr/local/bin/myapp
CMD ["myapp"]
```

Note: Some shared libraries may need to be installed as shown in the installation of the `extra-runtime-dependencies` line above.

This method will create an image that is less than 200mb. If you switch to using the Alpine-based rust image, you might be able to save another 60mb.

See https://docs.docker.com/develop/develop-images/multistage-build/ for more information.

## Compile your app inside the Docker container

There may be occasions where it is not appropriate to run your app inside a container. To compile, but not run your app inside the Docker instance, you can write something like:

```console
$ docker run --rm --user "$(id -u)":"$(id -g)" -v "$PWD":/usr/src/myapp -w /usr/src/myapp rust:1.23.0 cargo build --release
```

This will add your current directory, as a volume, to the container, set the working directory to the volume, and run the command `cargo build --release`. This tells Cargo, Rust's build system, to compile the crate in `myapp` and output the executable to `target/release/myapp`.

# Image Variants

The `rust` images come in many flavors, each designed for a specific use case.

## `rust:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like bookworm, bullseye, or trixie in them. These are the suite code names for releases of [Debian](https://wiki.debian.org/DebianReleases) and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

This tag is based off of [`buildpack-deps`](https://hub.docker.com/_/buildpack-deps/). `buildpack-deps` is designed for the average user of Docker who has many images on their system. It, by design, has a large number of extremely common Debian packages. This reduces the number of packages that images that derive from it need to install, thus reducing the overall size of all images on your system.

## `rust:<version>-slim`

This image does not contain the common packages contained in the default tag and only contains the minimal packages needed to run `rust`. Unless you are working in an environment where *only* the `rust` image will be deployed and you have space constraints, we highly recommend using the default image of this repository.

## `rust:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://www.rust-lang.org/en-US/legal.html) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `rust/` directory](https://github.com/docker-library/repo-info/tree/master/repos/rust).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
