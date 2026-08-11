<!--

********************************************************************************

WARNING:

    DO NOT EDIT "docker/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "docker/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Tianon (of the Docker Project)](https://github.com/docker-library/docker)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

(See ["What's the difference between 'Shared' and 'Simple' tags?" in the FAQ](https://github.com/docker-library/faq#whats-the-difference-between-shared-and-simple-tags).)

## Simple Tags

-	[`29.7.2-cli`, `29.7-cli`, `29-cli`, `cli`, `29.7.2-cli-alpine3.24`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/cli/Dockerfile)

-	[`29.7.2-dind`, `29.7-dind`, `29-dind`, `dind`, `29.7.2-dind-alpine3.24`, `29.7.2`, `29.7`, `29`, `latest`, `29.7.2-alpine3.24`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/dind/Dockerfile)

-	[`29.7.2-dind-rootless`, `29.7-dind-rootless`, `29-dind-rootless`, `dind-rootless`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/dind-rootless/Dockerfile)

-	[`29.7.2-windowsservercore-ltsc2025`, `29.7-windowsservercore-ltsc2025`, `29-windowsservercore-ltsc2025`, `windowsservercore-ltsc2025`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/windows/windowsservercore-ltsc2025/Dockerfile)

-	[`29.7.2-windowsservercore-ltsc2022`, `29.7-windowsservercore-ltsc2022`, `29-windowsservercore-ltsc2022`, `windowsservercore-ltsc2022`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/windows/windowsservercore-ltsc2022/Dockerfile)

## Shared Tags

-	`29.7.2-windowsservercore`, `29.7-windowsservercore`, `29-windowsservercore`, `windowsservercore`:

	-	[`29.7.2-windowsservercore-ltsc2025`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/windows/windowsservercore-ltsc2025/Dockerfile)
	-	[`29.7.2-windowsservercore-ltsc2022`](https://github.com/docker-library/docker/blob/3289af88086d67e6f0bfebfa0617541a0f574d96/29/windows/windowsservercore-ltsc2022/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/docker/issues](https://github.com/docker-library/docker/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/docker/), [`arm32v6`](https://hub.docker.com/r/arm32v6/docker/), [`arm32v7`](https://hub.docker.com/r/arm32v7/docker/), [`arm64v8`](https://hub.docker.com/r/arm64v8/docker/), [`windows-amd64`](https://hub.docker.com/r/winamd64/docker/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/docker/` directory](https://github.com/docker-library/repo-info/blob/master/repos/docker) ([history](https://github.com/docker-library/repo-info/commits/master/repos/docker))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/docker` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fdocker)  
	[official-images repo's `library/docker` file](https://github.com/docker-library/official-images/blob/master/library/docker) ([history](https://github.com/docker-library/official-images/commits/master/library/docker))

-	**Source of this description**:  
	[docs repo's `docker/` directory](https://github.com/docker-library/docs/tree/master/docker) ([history](https://github.com/docker-library/docs/commits/master/docker))

# What is Docker in Docker?

Although running Docker inside Docker is generally not recommended, there are some legitimate use cases, such as development of Docker itself.

*Docker is an open-source project that automates the deployment of applications inside software containers, by providing an additional layer of abstraction and automation of operating-system-level virtualization on Linux, Mac OS and Windows.*

> [wikipedia.org/wiki/Docker_(software)](https://en.wikipedia.org/wiki/Docker_%28software%29)

![logo](https://raw.githubusercontent.com/docker-library/docs/c350af05d3fac7b5c3f6327ac82fe4d990d8729c/docker/logo.png)

Before running Docker-in-Docker, be sure to read through [Jérôme Petazzoni's excellent blog post on the subject](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/), where he outlines some of the pros and cons of doing so (and some nasty gotchas you might run into).

If you are still convinced that you need Docker-in-Docker and not just access to a container's host Docker server, then read on.

# How to use this image

[![asciicast](https://asciinema.org/a/378669.svg)](https://asciinema.org/a/378669)

## TLS

Starting in 18.09+, the `dind` variants of this image will automatically generate TLS certificates in the directory specified by the `DOCKER_TLS_CERTDIR` environment variable.

**Warning:** in 18.09, this behavior is disabled by default (for compatibility). If you use `--network=host`, shared network namespaces (as in Kubernetes pods), or otherwise have network access to the container (including containers started within the `dind` instance via their gateway interface), this is a potential security issue (which can lead to access to the host system, for example). It is recommended to enable TLS by setting the variable to an appropriate value (`-e DOCKER_TLS_CERTDIR=/certs` or similar). In 19.03+, this behavior is enabled by default.

When enabled, the Docker daemon will be started with `--host=tcp://0.0.0.0:2376 --tlsverify ...` (and when disabled, the Docker daemon will be started with `--host=tcp://0.0.0.0:2375`).

Inside the directory specified by `DOCKER_TLS_CERTDIR`, the entrypoint scripts will create/use three directories:

-	`ca`: the certificate authority files (`cert.pem`, `key.pem`)
-	`server`: the `dockerd` (daemon) certificate files (`cert.pem`, `ca.pem`, `key.pem`)
-	`client`: the `docker` (client) certificate files (`cert.pem`, `ca.pem`, `key.pem`; suitable for `DOCKER_CERT_PATH`)

In order to make use of this functionality from a "client" container, at least the `client` subdirectory of the `$DOCKER_TLS_CERTDIR` directory needs to be shared (as illustrated in the following examples).

To disable this image behavior, simply override the container command or entrypoint to run `dockerd` directly (`... docker:dind dockerd ...` or `... --entrypoint dockerd docker:dind ...`).

## Start a daemon instance

```console
$ docker run --privileged --name some-docker -d \
	--network some-network --network-alias docker \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v some-docker-certs-ca:/certs/ca \
	-v some-docker-certs-client:/certs/client \
	docker:dind
```

**Note:** `--privileged` is required for Docker-in-Docker to function properly, but it should be used with care as it provides full access to the host environment, as explained [in the relevant section of the Docker documentation](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

## Connect to it from a second container

```console
$ docker run --rm --network some-network \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v some-docker-certs-client:/certs/client:ro \
	docker:latest version
Client: Docker Engine - Community
 Version:           18.09.8
 API version:       1.39
 Go version:        go1.10.8
 Git commit:        0dd43dd87f
 Built:             Wed Jul 17 17:38:58 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.8
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.8
  Git commit:       0dd43dd87f
  Built:            Wed Jul 17 17:48:49 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```

```console
$ docker run -it --rm --network some-network \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v some-docker-certs-client:/certs/client:ro \
	docker:latest sh
/ # docker version
Client: Docker Engine - Community
 Version:           18.09.8
 API version:       1.39
 Go version:        go1.10.8
 Git commit:        0dd43dd87f
 Built:             Wed Jul 17 17:38:58 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.8
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.8
  Git commit:       0dd43dd87f
  Built:            Wed Jul 17 17:48:49 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```

```console
$ docker run --rm --network some-network \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v some-docker-certs-client:/certs/client:ro \
	docker:latest info
Containers: 0
 Running: 0
 Paused: 0
 Stopped: 0
Images: 0
Server Version: 18.09.8
Storage Driver: overlay2
 Backing Filesystem: extfs
 Supports d_type: true
 Native Overlay Diff: true
Logging Driver: json-file
Cgroup Driver: cgroupfs
Plugins:
 Volume: local
 Network: bridge host macvlan null overlay
 Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
Swarm: inactive
Runtimes: runc
Default Runtime: runc
Init Binary: docker-init
containerd version: 894b81a4b802e4eb2a91d1ce216b8817763c29fb
runc version: 425e105d5a03fabd737a126ad93d62a9eeede87f
init version: fec3683
Security Options:
 apparmor
 seccomp
  Profile: default
Kernel Version: 4.19.0-5-amd64
Operating System: Alpine Linux v3.10 (containerized)
OSType: linux
Architecture: x86_64
CPUs: 12
Total Memory: 62.79GiB
Name: e174d61a4a12
ID: HJXG:3OT7:MGDL:Y2BL:WCYP:CKSP:CGAM:4BLH:NEI4:IURF:4COF:AH6N
Docker Root Dir: /var/lib/docker
Debug Mode (client): false
Debug Mode (server): false
Registry: https://index.docker.io/v1/
Labels:
Experimental: false
Insecure Registries:
 127.0.0.0/8
Live Restore Enabled: false
Product License: Community Engine

WARNING: bridge-nf-call-iptables is disabled
WARNING: bridge-nf-call-ip6tables is disabled
```

```console
$ docker run --rm -v /var/run/docker.sock:/var/run/docker.sock docker:latest version
Client: Docker Engine - Community
 Version:           18.09.8
 API version:       1.39
 Go version:        go1.10.8
 Git commit:        0dd43dd87f
 Built:             Wed Jul 17 17:38:58 2019
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          18.09.7
  API version:      1.39 (minimum version 1.12)
  Go version:       go1.10.8
  Git commit:       2d0083d
  Built:            Thu Jun 27 17:23:02 2019
  OS/Arch:          linux/amd64
  Experimental:     false
```

## Custom daemon flags

```console
$ docker run --privileged --name some-docker -d \
	--network some-network --network-alias docker \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v some-docker-certs-ca:/certs/ca \
	-v some-docker-certs-client:/certs/client \
	docker:dind --storage-driver overlay2
```

## Runtime Settings Considerations

Inspired by the [official systemd `docker.service` configuration](https://github.com/docker/docker-ce-packaging/blob/57ae892b13de399171fc33f878b70e72855747e6/systemd/docker.service#L30-L45), you may want to consider different values for the following runtime configuration options, especially for production Docker instances:

```console
$ docker run --privileged --name some-docker -d \
	... \
	--ulimit nofile=-1 \
	--ulimit nproc=-1 \
	--ulimit core=-1 \
	--pids-limit -1 \
	--oom-score-adj -500 \
	docker:dind
```

Some of these will not be supported based on the settings on the host's `dockerd`, such as `--ulimit nofile=-1`, giving errors that look like `error setting rlimit type 7: operation not permitted`, and some may inherit sane values from the host `dockerd` instance or may not apply for your usage of Docker-in-Docker (for example, you likely want to set `--oom-score-adj` to a value that's higher than `dockerd` on the host so that your Docker-in-Docker instance is killed before the host Docker instance is).

## Where to Store Data

Important note: There are several ways to store data used by applications that run in Docker containers. We encourage users of the `docker` images to familiarize themselves with the options available, including:

-	Let Docker manage the storage of your data [by writing to disk on the host system using its own internal volume management](https://docs.docker.com/storage/volumes/). This is the default and is easy and fairly transparent to the user. The downside is that the files may be hard to locate for tools and applications that run directly on the host system, i.e. outside containers.
-	Create a data directory on the host system (outside the container) and [mount this to a directory visible from inside the container](https://docs.docker.com/storage/bind-mounts/). This places the files in a known location on the host system, and makes it easy for tools and applications on the host system to access the files. The downside is that the user needs to make sure that the directory exists, and that e.g. directory permissions and other security mechanisms on the host system are set up correctly.

The Docker documentation is a good starting point for understanding the different storage options and variations, and there are multiple blogs and forum postings that discuss and give advice in this area. We will simply show the basic procedure here for the latter option above:

1.	Create a data directory on a suitable volume on your host system, e.g. `/my/own/var-lib-docker`.
2.	Start your `docker` container like this:

	```console
	$ docker run --privileged --name some-docker -v /my/own/var-lib-docker:/var/lib/docker -d docker:dind
	```

The `-v /my/own/var-lib-docker:/var/lib/docker` part of the command mounts the `/my/own/var-lib-docker` directory from the underlying host system as `/var/lib/docker` inside the container, where Docker by default will write its data files.

# Image Variants

The `docker` images come in many flavors, each designed for a specific use case.

**Note:** The `docker:stable`, `docker:test`, and related "channel" tags have been deprecated since June 2020 (see [docker-library/docker#179](https://github.com/docker-library/docker/pull/179)) and have not been updated since December 2020 (when Docker 20.10 was released). Suggested alternatives are below. `X` is a placeholder for the version; see the supported tags list for the current set of tags.

-	`docker:stable` ⏩ `docker:latest`, `docker:dind`, `docker:X`, `docker:cli`, etc
-	`docker:test` ⏩ `docker:rc`, `docker:rc-dind`, `docker:X-rc`, `docker:rc-cli`, etc (only updated when there is an active pre-release; will not point to the same thing as `latest`)

## `docker:<version>-cli`

This image contains the Docker client command line interface (CLI) and Docker CLI plugins like `buildx` and `compose`. This is useful if you need to interact with a remote Docker engine but aren't planning to run the Docker engine in the container.

## `docker:<version>`, `docker:<version>-dind`

The default variant is the Docker in Docker variant. It contains the Docker engine as well as the Docker CLI and plugins that are included in the `cli` variant. It is useful for running Docker in Docker and for interacting with a Docker engine via the Docker CLI.

## `docker:<version>-rootless`

For more information about using the experimental "rootless" image variants, see [docker-library/docker#174](https://github.com/docker-library/docker/pull/174).

**Note:** just like the regular `dind` images, `--privileged` is required for Docker-in-Docker to function properly ([docker-library/docker#151](https://github.com/docker-library/docker/issues/151#issuecomment-483185972) & [docker-library/docker#281](https://github.com/docker-library/docker/issues/281#issuecomment-744766015)), which is a security issue that needs to be treated appropriately.

Basic example usage:

```console
$ docker run -d --name some-docker --privileged docker:dind-rootless
$ docker logs --tail=3 some-docker # to verify the daemon has finished generating TLS certificates and is listening successfully
time="xxx" level=info msg="Daemon has completed initialization"
time="xxx" level=info msg="API listen on /run/user/1000/docker.sock"
time="xxx" level=info msg="API listen on [::]:2376"
$ docker exec -it some-docker docker-entrypoint.sh sh # using "docker-entrypoint.sh" which auto-sets "DOCKER_HOST" appropriately
/ $ docker info --format '{{ json .SecurityOptions }}'
["name=seccomp,profile=default","name=rootless"]
```

To run with a different UID/GID than the one baked into the image, modify `/etc/passwd`, `/etc/group`, and filesystem permissions (especially for the `rootless` user's home directory) as appropriate; for example:

```dockerfile
FROM docker:dind-rootless
USER root
RUN set -eux; \
	sed -i -e 's/^rootless:x:1000:1000:/rootless:x:1234:5678:/' /etc/passwd; \
	sed -i -e 's/^rootless:x:1000:/rootless:x:5678:/' /etc/group; \
	chown -R rootless ~rootless
USER rootless
```

## `docker:<version>-windowsservercore`

Unfortunately, Windows does not support nested containers, so this image variant only contains the client (intended for use against an existing Docker engine, ala `-v //./pipe/docker_engine://./pipe/docker_engine`).

# License

View [license information](https://github.com/docker/docker/blob/eb7b2ed6bbe3fbef588116d362ce595d6e35fc43/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `docker/` directory](https://github.com/docker-library/repo-info/tree/master/repos/docker).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
