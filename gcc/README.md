<!--

********************************************************************************

WARNING:

    DO NOT EDIT "gcc/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "gcc/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Docker Community](https://github.com/docker-library/gcc)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`16.2.0`, `16.2`, `16`, `latest`, `16.2.0-trixie`, `16.2-trixie`, `16-trixie`, `trixie`](https://github.com/docker-library/gcc/blob/ec9b92635140e2869eb3aad9b7a921b47ec54e50/16/Dockerfile)

-	[`15.3.0`, `15.3`, `15`, `15.3.0-trixie`, `15.3-trixie`, `15-trixie`](https://github.com/docker-library/gcc/blob/3b87fe3e286f7aa21ed5d69fd5c39e1b4fb02057/15/Dockerfile)

-	[`14.4.0`, `14.4`, `14`, `14.4.0-trixie`, `14.4-trixie`, `14-trixie`](https://github.com/docker-library/gcc/blob/d0fb67beca5c8248b88c7e5271ab34b4fdb279a0/14/Dockerfile)

-	[`13.4.0`, `13.4`, `13`, `13.4.0-bookworm`, `13.4-bookworm`, `13-bookworm`](https://github.com/docker-library/gcc/blob/118c07a8e6467baababb4634b6cfde14a67c24b0/13/Dockerfile)

-	[`12.5.0`, `12.5`, `12`, `12.5.0-bookworm`, `12.5-bookworm`, `12-bookworm`](https://github.com/docker-library/gcc/blob/7070981b23d22d3ca790f87bff26f13f3614dd4c/12/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/gcc/issues](https://github.com/docker-library/gcc/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/gcc/), [`arm32v5`](https://hub.docker.com/r/arm32v5/gcc/), [`arm32v7`](https://hub.docker.com/r/arm32v7/gcc/), [`arm64v8`](https://hub.docker.com/r/arm64v8/gcc/), [`ppc64le`](https://hub.docker.com/r/ppc64le/gcc/), [`s390x`](https://hub.docker.com/r/s390x/gcc/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/gcc/` directory](https://github.com/docker-library/repo-info/blob/master/repos/gcc) ([history](https://github.com/docker-library/repo-info/commits/master/repos/gcc))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/gcc` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fgcc)  
	[official-images repo's `library/gcc` file](https://github.com/docker-library/official-images/blob/master/library/gcc) ([history](https://github.com/docker-library/official-images/commits/master/library/gcc))

-	**Source of this description**:  
	[docs repo's `gcc/` directory](https://github.com/docker-library/docs/tree/master/gcc) ([history](https://github.com/docker-library/docs/commits/master/gcc))

# What is GCC?

The GNU Compiler Collection (GCC) is a compiler system produced by the GNU Project that supports various programming languages. GCC is a key component of the GNU toolchain. The Free Software Foundation (FSF) distributes GCC under the GNU General Public License (GNU GPL). GCC has played an important role in the growth of free software, as both a tool and an example.

> [wikipedia.org/wiki/GNU_Compiler_Collection](https://en.wikipedia.org/wiki/GNU_Compiler_Collection)

![logo](https://raw.githubusercontent.com/docker-library/docs/60b29a700d22613526487c7d5fcf4d723ed2ef0a/gcc/logo.png)

# How to use this image

## Start a GCC instance running your app

The most straightforward way to use this image is to use a gcc container as both the build and runtime environment. In your `Dockerfile`, writing something along the lines of the following will compile and run your project:

```dockerfile
FROM gcc:4.9
COPY . /usr/src/myapp
WORKDIR /usr/src/myapp
RUN gcc -o myapp main.c
CMD ["./myapp"]
```

Then, build and run the Docker image:

```console
$ docker build -t my-gcc-app .
$ docker run -it --rm --name my-running-app my-gcc-app
```

## Compile your app inside the Docker container

There may be occasions where it is not appropriate to run your app inside a container. To compile, but not run your app inside the Docker instance, you can write something like:

```console
$ docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp gcc:4.9 gcc -o myapp myapp.c
```

This will add your current directory, as a volume, to the container, set the working directory to the volume, and run the command `gcc -o myapp myapp.c.` This tells gcc to compile the code in `myapp.c` and output the executable to myapp. Alternatively, if you have a `Makefile`, you can instead run the `make` command inside your container:

```console
$ docker run --rm -v "$PWD":/usr/src/myapp -w /usr/src/myapp gcc:4.9 make
```

# License

View [license information](https://gcc.gnu.org/onlinedocs/gcc-11.2.0/gcc/Copying.html) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `gcc/` directory](https://github.com/docker-library/repo-info/tree/master/repos/gcc).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
