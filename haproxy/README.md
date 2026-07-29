<!--

********************************************************************************

WARNING:

    DO NOT EDIT "haproxy/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "haproxy/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Docker Community](https://github.com/docker-library/haproxy)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`3.5-dev3`, `3.5-dev`, `3.5-dev3-trixie`, `3.5-dev-trixie`](https://github.com/docker-library/haproxy/blob/ec437dd2a3656610b10a42c08763d8fa1c591efe/3.5/Dockerfile)

-	[`3.5-dev3-alpine`, `3.5-dev-alpine`, `3.5-dev3-alpine3.24`, `3.5-dev-alpine3.24`](https://github.com/docker-library/haproxy/blob/ec437dd2a3656610b10a42c08763d8fa1c591efe/3.5/alpine/Dockerfile)

-	[`3.4.3`, `3.4`, `latest`, `lts`, `3.4.3-trixie`, `3.4-trixie`, `trixie`, `lts-trixie`](https://github.com/docker-library/haproxy/blob/40955df2217f5cb77f861e709b239cedd43ff613/3.4/Dockerfile)

-	[`3.4.3-alpine`, `3.4-alpine`, `alpine`, `lts-alpine`, `3.4.3-alpine3.24`, `3.4-alpine3.24`, `alpine3.24`, `lts-alpine3.24`](https://github.com/docker-library/haproxy/blob/40955df2217f5cb77f861e709b239cedd43ff613/3.4/alpine/Dockerfile)

-	[`3.3.13`, `3.3`, `3.3.13-trixie`, `3.3-trixie`](https://github.com/docker-library/haproxy/blob/caa8282e7c19d57d87610ffb13560ee8ccbc263f/3.3/Dockerfile)

-	[`3.3.13-alpine`, `3.3-alpine`, `3.3.13-alpine3.24`, `3.3-alpine3.24`](https://github.com/docker-library/haproxy/blob/caa8282e7c19d57d87610ffb13560ee8ccbc263f/3.3/alpine/Dockerfile)

-	[`3.2.22`, `3.2`, `3.2.22-trixie`, `3.2-trixie`](https://github.com/docker-library/haproxy/blob/3e679de0fb5d9e781f1aa313ab7464e270a809e3/3.2/Dockerfile)

-	[`3.2.22-alpine`, `3.2-alpine`, `3.2.22-alpine3.24`, `3.2-alpine3.24`](https://github.com/docker-library/haproxy/blob/3e679de0fb5d9e781f1aa313ab7464e270a809e3/3.2/alpine/Dockerfile)

-	[`3.0.25`, `3.0`, `3.0.25-trixie`, `3.0-trixie`](https://github.com/docker-library/haproxy/blob/84fe98d090e7617a2d94e7ad7cfb16c14cd1a560/3.0/Dockerfile)

-	[`3.0.25-alpine`, `3.0-alpine`, `3.0.25-alpine3.24`, `3.0-alpine3.24`](https://github.com/docker-library/haproxy/blob/84fe98d090e7617a2d94e7ad7cfb16c14cd1a560/3.0/alpine/Dockerfile)

-	[`2.8.27`, `2.8`, `2.8.27-trixie`, `2.8-trixie`](https://github.com/docker-library/haproxy/blob/2ee81bd76371730aa58585c7f281acd89334f7bb/2.8/Dockerfile)

-	[`2.8.27-alpine`, `2.8-alpine`, `2.8.27-alpine3.24`, `2.8-alpine3.24`](https://github.com/docker-library/haproxy/blob/2ee81bd76371730aa58585c7f281acd89334f7bb/2.8/alpine/Dockerfile)

-	[`2.6.32`, `2.6`, `2.6.32-trixie`, `2.6-trixie`](https://github.com/docker-library/haproxy/blob/32a1b4183b2b02c1dd8060bca6c706285ca1245f/2.6/Dockerfile)

-	[`2.6.32-alpine`, `2.6-alpine`, `2.6.32-alpine3.24`, `2.6-alpine3.24`](https://github.com/docker-library/haproxy/blob/32a1b4183b2b02c1dd8060bca6c706285ca1245f/2.6/alpine/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/docker-library/haproxy/issues](https://github.com/docker-library/haproxy/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/haproxy/), [`arm32v5`](https://hub.docker.com/r/arm32v5/haproxy/), [`arm32v6`](https://hub.docker.com/r/arm32v6/haproxy/), [`arm32v7`](https://hub.docker.com/r/arm32v7/haproxy/), [`arm64v8`](https://hub.docker.com/r/arm64v8/haproxy/), [`i386`](https://hub.docker.com/r/i386/haproxy/), [`ppc64le`](https://hub.docker.com/r/ppc64le/haproxy/), [`riscv64`](https://hub.docker.com/r/riscv64/haproxy/), [`s390x`](https://hub.docker.com/r/s390x/haproxy/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/haproxy/` directory](https://github.com/docker-library/repo-info/blob/master/repos/haproxy) ([history](https://github.com/docker-library/repo-info/commits/master/repos/haproxy))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/haproxy` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fhaproxy)  
	[official-images repo's `library/haproxy` file](https://github.com/docker-library/official-images/blob/master/library/haproxy) ([history](https://github.com/docker-library/official-images/commits/master/library/haproxy))

-	**Source of this description**:  
	[docs repo's `haproxy/` directory](https://github.com/docker-library/docs/tree/master/haproxy) ([history](https://github.com/docker-library/docs/commits/master/haproxy))

# What is HAProxy?

HAProxy is a free, open source high availability solution, providing load balancing and proxying for TCP and HTTP-based applications by spreading requests across multiple servers. It is written in C and has a reputation for being fast and efficient (in terms of processor and memory usage).

> [wikipedia.org/wiki/HAProxy](https://en.wikipedia.org/wiki/HAProxy)

![logo](https://raw.githubusercontent.com/docker-library/docs/4da3e2446a4c257c3a32faac6256bee81f770316/haproxy/logo.png)

# How to use this image

Since no two users of HAProxy are likely to configure it exactly alike, this image does not come with any default configuration.

Please refer to [upstream's excellent (and comprehensive) documentation](https://docs.haproxy.org/) on the subject of configuring HAProxy for your needs.

It is also worth checking out the [`examples/` directory from upstream](http://git.haproxy.org/?p=haproxy-2.3.git;a=tree;f=examples).

## Create a `Dockerfile`

```dockerfile
FROM haproxy:2.3
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

## Build the container

```console
$ docker build -t my-haproxy .
```

## Test the configuration file

```console
$ docker run -it --rm --name haproxy-syntax-check my-haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
```

## Run the container

```console
$ docker run -d --name my-running-haproxy --sysctl net.ipv4.ip_unprivileged_port_start=0 my-haproxy
```

You will need a kernel at [version 4.11 or newer](https://github.com/moby/moby/issues/8460#issuecomment-312459310) to use `--sysctl net.ipv4.ip_unprivileged_port_start=0` , you may need to publish the ports your HAProxy is listening on to the host by specifying the -p option, for example -p 8080:80 to publish port 8080 from the container host to port 80 in the container. Make sure the port you're using is free.

**Note:** the 2.4+ versions of the container will run as `USER haproxy` by default (hence the `--sysctl net.ipv4.ip_unprivileged_port_start=0` above), but older versions still default to `root` for compatibility reasons; use `--user haproxy` (or any other UID) if you want to run as non-root in older versions.

## Directly via bind mount

```console
$ docker run -d --name my-running-haproxy -v /path/to/etc/haproxy:/usr/local/etc/haproxy:ro --sysctl net.ipv4.ip_unprivileged_port_start=0 haproxy:2.3
```

Note that your host's `/path/to/etc/haproxy` folder should be populated with a file named `haproxy.cfg`. If this configuration file refers to any other files within that folder then you should ensure that they also exist (e.g. template files such as `400.http`, `404.http`, and so forth). However, many minimal configurations do not require any supporting files.

### Reloading config

If you used a bind mount for the config and have edited your `haproxy.cfg` file, you can use HAProxy's graceful reload feature by sending a `SIGHUP` to the container:

```console
$ docker kill -s HUP my-running-haproxy
```

The entrypoint script in the image checks for running the command `haproxy` and replaces it with `haproxy-systemd-wrapper` from HAProxy upstream which takes care of signal handling to do the graceful reload. Under the hood this uses the `-sf` option of `haproxy` so "there are two small windows of a few milliseconds each where it is possible that a few connection failures will be noticed during high loads" (see [Stopping and restarting HAProxy](http://www.haproxy.org/download/2.3/doc/management.txt)).

# Image Variants

The `haproxy` images come in many flavors, each designed for a specific use case.

## `haproxy:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like trixie in them. These are the suite code names for releases of [Debian](https://wiki.debian.org/DebianReleases) and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

## `haproxy:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](http://www.haproxy.org/download/1.5/doc/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `haproxy/` directory](https://github.com/docker-library/repo-info/tree/master/repos/haproxy).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
