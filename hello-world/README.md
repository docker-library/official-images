<!--

********************************************************************************

WARNING:

    DO NOT EDIT "hello-world/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "hello-world/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Docker Community](https://github.com/docker-library/hello-world)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

(See ["What's the difference between 'Shared' and 'Simple' tags?" in the FAQ](https://github.com/docker-library/faq#whats-the-difference-between-shared-and-simple-tags).)

## Simple Tags

-	[`linux`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/Dockerfile)

-	[`nanoserver-ltsc2025`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2025/Dockerfile)

-	[`nanoserver-ltsc2022`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2022/Dockerfile)

## Shared Tags

-	`latest`:

	-	[`linux`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/Dockerfile)
	-	[`nanoserver-ltsc2025`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2025/Dockerfile)
	-	[`nanoserver-ltsc2022`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2022/Dockerfile)

-	`nanoserver`:

	-	[`nanoserver-ltsc2025`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2025/Dockerfile)
	-	[`nanoserver-ltsc2022`](https://github.com/docker-library/hello-world/blob/3981a44a531e7c844d844e12cbbda232d10d5dfb/amd64/nanoserver-ltsc2022/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/hello-world/issues](https://github.com/docker-library/hello-world/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/hello-world/), [`arm32v5`](https://hub.docker.com/r/arm32v5/hello-world/), [`arm32v6`](https://hub.docker.com/r/arm32v6/hello-world/), [`arm32v7`](https://hub.docker.com/r/arm32v7/hello-world/), [`arm64v8`](https://hub.docker.com/r/arm64v8/hello-world/), [`i386`](https://hub.docker.com/r/i386/hello-world/), [`ppc64le`](https://hub.docker.com/r/ppc64le/hello-world/), [`riscv64`](https://hub.docker.com/r/riscv64/hello-world/), [`s390x`](https://hub.docker.com/r/s390x/hello-world/), [`windows-amd64`](https://hub.docker.com/r/winamd64/hello-world/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/hello-world/` directory](https://github.com/docker-library/repo-info/blob/master/repos/hello-world) ([history](https://github.com/docker-library/repo-info/commits/master/repos/hello-world))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/hello-world` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fhello-world)  
	[official-images repo's `library/hello-world` file](https://github.com/docker-library/official-images/blob/master/library/hello-world) ([history](https://github.com/docker-library/official-images/commits/master/library/hello-world))

-	**Source of this description**:  
	[docs repo's `hello-world/` directory](https://github.com/docker-library/docs/tree/master/hello-world) ([history](https://github.com/docker-library/docs/commits/master/hello-world))

# Example output

```console
$ docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/


$ docker images hello-world
REPOSITORY    TAG       IMAGE ID       SIZE
hello-world   latest    e2ac70e7319a   10.07kB
```

![logo](https://raw.githubusercontent.com/docker-library/docs/01c12653951b2fe592c1f93a13b4e289ada0e3a1/hello-world/logo.png)

# How is this image created?

This image is a prime example of using the [`scratch`](https://hub.docker.com/_/scratch/) image effectively. See [`hello.c`](https://github.com/docker-library/hello-world/blob/master/hello.c) in https://github.com/docker-library/hello-world for the source code of the `hello` binary included in this image.

Because this image consists of nothing but a single static binary which prints some text to standard output, it can trivially be run as any arbitrary user (`docker run --user $RANDOM:$RANDOM hello-world`, for example).

# License

View [license information](https://github.com/docker-library/hello-world/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `hello-world/` directory](https://github.com/docker-library/repo-info/tree/master/repos/hello-world).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
