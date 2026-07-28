<!--

********************************************************************************

WARNING:

    DO NOT EDIT "nim/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "nim/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Nim Core Team](https://github.com/nim-lang/docker-images)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`2.2.10`, `2.2`, `2`, `latest`](https://github.com/nim-lang/docker-images/blob/c8df5e79155477e213137e4e42a7ea422d2a3851/dockerfiles/2.2.10/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/nim-lang/docker-images/issues](https://github.com/nim-lang/docker-images/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/nim/), [`arm64v8`](https://hub.docker.com/r/arm64v8/nim/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/nim/` directory](https://github.com/docker-library/repo-info/blob/master/repos/nim) ([history](https://github.com/docker-library/repo-info/commits/master/repos/nim))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/nim` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fnim)  
	[official-images repo's `library/nim` file](https://github.com/docker-library/official-images/blob/master/library/nim) ([history](https://github.com/docker-library/official-images/commits/master/library/nim))

-	**Source of this description**:  
	[docs repo's `nim/` directory](https://github.com/docker-library/docs/tree/master/nim) ([history](https://github.com/docker-library/docs/commits/master/nim))

# What is Nim?

[Nim](https://nim-lang.org/) is a statically typed, imperative programming language that focuses on efficiency, expressiveness, and elegance. It is designed to be as fast as C and as readable as Python, while offering a powerful macro system for metaprogramming.

> [nim-lang.org](https://nim-lang.org/)

![logo](https://raw.githubusercontent.com/docker-library/docs/ac6bc61f3f986df1f39aa351b0d077a16c091639/nim/logo.svg?sanitize=true)

# How to use this image

## Compile and run a Nim program (C backend)

To compile a file named `main.nim` and execute it immediately:

```console
$ docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app nim nim c -r main.nim
```

## Compile to JavaScript

Nim can compile to JavaScript:

```console
$ docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app nim nim js main.nim
```

To compile and run, use a multi-stage Dockerfile with Node.js:

```dockerfile
FROM nim AS builder
COPY . .
RUN nim js -o:app.js src/app.nim

FROM node:latest
COPY --from=builder /usr/src/app/app.js .
CMD ["node", "app.js"]
```

## Managing packages with Nimble

The image is configured with SSL support to allow Nimble to install packages from remote repositories:

```console
$ docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app nim nimble install -y
```

## Dockerfile example

```dockerfile
FROM nim

WORKDIR /usr/src/app

COPY *.nimble .
RUN nimble install --depsOnly -y

COPY . .
RUN nimble build

CMD ["./yourapp"]
```

# License

View [license information](https://github.com/nim-lang/Nim/blob/devel/copying.txt) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `nim/` directory](https://github.com/docker-library/repo-info/tree/master/repos/nim).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
