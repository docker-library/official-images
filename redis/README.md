<!--

********************************************************************************

WARNING:

    DO NOT EDIT "redis/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "redis/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[Redis LTD](https://redis.io/)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`8.10.0`, `8.10`, `8`, `8.10.0-trixie`, `8.10-trixie`, `8-trixie`, `latest`, `trixie`](https://github.com/redis/docker-library-redis/blob/0a24b09f88a6cb8feaf130d4eca7bd6b9b4c73a3/debian/Dockerfile)

-	[`8.10.0-alpine`, `8.10-alpine`, `8-alpine`, `8.10.0-alpine3.23`, `8.10-alpine3.23`, `8-alpine3.23`, `alpine`, `alpine3.23`](https://github.com/redis/docker-library-redis/blob/0a24b09f88a6cb8feaf130d4eca7bd6b9b4c73a3/alpine/Dockerfile)

-	[`8.8.1`, `8.8`, `8.8.1-trixie`, `8.8-trixie`](https://github.com/redis/docker-library-redis/blob/b675641c81d9f476e614aee4a6606365548bae41/debian/Dockerfile)

-	[`8.8.1-alpine`, `8.8-alpine`, `8.8.1-alpine3.23`, `8.8-alpine3.23`](https://github.com/redis/docker-library-redis/blob/b675641c81d9f476e614aee4a6606365548bae41/alpine/Dockerfile)

-	[`8.6.5`, `8.6`, `8.6.5-trixie`, `8.6-trixie`](https://github.com/redis/docker-library-redis/blob/8bf384f30957c89ea17a1fd6e5f34ed31065f84b/debian/Dockerfile)

-	[`8.6.5-alpine`, `8.6-alpine`, `8.6.5-alpine3.23`, `8.6-alpine3.23`](https://github.com/redis/docker-library-redis/blob/8bf384f30957c89ea17a1fd6e5f34ed31065f84b/alpine/Dockerfile)

-	[`8.4.5`, `8.4`, `8.4.5-trixie`, `8.4-trixie`](https://github.com/redis/docker-library-redis/blob/cc3829e8d874f31c8d50ee1e7a81f283eaa9688a/debian/Dockerfile)

-	[`8.4.5-alpine`, `8.4-alpine`, `8.4.5-alpine3.22`, `8.4-alpine3.22`](https://github.com/redis/docker-library-redis/blob/cc3829e8d874f31c8d50ee1e7a81f283eaa9688a/alpine/Dockerfile)

-	[`8.2.8`, `8.2`, `8.2.8-bookworm`, `8.2-bookworm`](https://github.com/redis/docker-library-redis/blob/3769a841048d940966635f8f59471f3d350707bf/debian/Dockerfile)

-	[`8.2.8-alpine`, `8.2-alpine`, `8.2.8-alpine3.22`, `8.2-alpine3.22`](https://github.com/redis/docker-library-redis/blob/3769a841048d940966635f8f59471f3d350707bf/alpine/Dockerfile)

-	[`7.4.10`, `7.4`, `7`, `7.4.10-bookworm`, `7.4-bookworm`, `7-bookworm`](https://github.com/redis/docker-library-redis/blob/31c68732e7311d95e4c833b8fa50aa561ced577f/debian/Dockerfile)

-	[`7.4.10-alpine`, `7.4-alpine`, `7-alpine`, `7.4.10-alpine3.21`, `7.4-alpine3.21`, `7-alpine3.21`](https://github.com/redis/docker-library-redis/blob/31c68732e7311d95e4c833b8fa50aa561ced577f/alpine/Dockerfile)

-	[`7.2.15`, `7.2`, `7.2.15-bookworm`, `7.2-bookworm`](https://github.com/redis/docker-library-redis/blob/976a7de4cd78b6a201b4a3a5ac49cd9c8e3e583f/debian/Dockerfile)

-	[`7.2.15-alpine`, `7.2-alpine`, `7.2.15-alpine3.21`, `7.2-alpine3.21`](https://github.com/redis/docker-library-redis/blob/976a7de4cd78b6a201b4a3a5ac49cd9c8e3e583f/alpine/Dockerfile)

-	[`6.2.23`, `6.2`, `6`, `6.2.23-bookworm`, `6.2-bookworm`, `6-bookworm`](https://github.com/redis/docker-library-redis/blob/70d903a68609970bf9a66181cdc59d0fc1ebc885/debian/Dockerfile)

-	[`6.2.23-alpine`, `6.2-alpine`, `6-alpine`, `6.2.23-alpine3.21`, `6.2-alpine3.21`, `6-alpine3.21`](https://github.com/redis/docker-library-redis/blob/70d903a68609970bf9a66181cdc59d0fc1ebc885/alpine/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/redis/docker-library-redis/issues](https://github.com/redis/docker-library-redis/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/redis/), [`arm32v5`](https://hub.docker.com/r/arm32v5/redis/), [`arm32v6`](https://hub.docker.com/r/arm32v6/redis/), [`arm32v7`](https://hub.docker.com/r/arm32v7/redis/), [`arm64v8`](https://hub.docker.com/r/arm64v8/redis/), [`i386`](https://hub.docker.com/r/i386/redis/), [`mips64le`](https://hub.docker.com/r/mips64le/redis/), [`ppc64le`](https://hub.docker.com/r/ppc64le/redis/), [`riscv64`](https://hub.docker.com/r/riscv64/redis/), [`s390x`](https://hub.docker.com/r/s390x/redis/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/redis/` directory](https://github.com/docker-library/repo-info/blob/master/repos/redis) ([history](https://github.com/docker-library/repo-info/commits/master/repos/redis))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/redis` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fredis)  
	[official-images repo's `library/redis` file](https://github.com/docker-library/official-images/blob/master/library/redis) ([history](https://github.com/docker-library/official-images/commits/master/library/redis))

-	**Source of this description**:  
	[docs repo's `redis/` directory](https://github.com/docker-library/docs/tree/master/redis) ([history](https://github.com/docker-library/docs/commits/master/redis))

# What is Redis?

Redis is the world’s fastest data platform. It provides cloud and on-prem solutions for caching, vector search, and NoSQL databases that seamlessly fit into any tech stack&mdash;making it simple for digital customers to build, scale, and deploy the fast apps our world runs on.

> [redis.io](https://redis.io)

![logo](https://raw.githubusercontent.com/docker-library/docs/0e42ee108b46e1ba6333e9eb44201b8f26c4032d/redis/logo.png)

# Security

For the ease of accessing Redis from other containers via Docker networking, the "Protected mode" is turned off by default. This means that if you expose the port outside of your host (e.g., via `-p` on `docker run`), it will be open without a password to anyone. It is **highly** recommended to set a password (by supplying a config file) if you plan on exposing your Redis instance to the internet. For further information, see the following links about Redis security:

-	[Redis documentation on security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
-	[Protected mode](https://redis.io/docs/latest/operate/oss_and_stack/management/security/#protected-mode)
-	[A few things about Redis security by antirez](http://antirez.com/news/96)

## Process User and Privileges

By default, the Redis Docker image drops privileges by switching to the redis user and removing unnecessary capabilities. This step is skipped if Docker is run with the `--user` option or if you set the `SKIP_DROP_PRIVS=1` (since 8.0.2) environment variable.

Note: Using `SKIP_DROP_PRIVS` is not recommended, as it reduces the container's security.

# How to use this image

## Start a redis instance

```console
$ docker run --name some-redis -d redis
```

## Start with persistent storage

```console
$ docker run --name some-redis -d redis redis-server --save 60 1 --loglevel warning
```

There are several different persistence strategies to choose from. This one will save a snapshot of the DB every 60 seconds if at least 1 write operation was performed (it will also lead to more logs, so the `loglevel` option may be desirable). If persistence is enabled, data is stored in the `VOLUME /data`, which can be used with `--volumes-from some-volume-container` or `-v /docker/host/dir:/data` (see [docs.docker volumes](https://docs.docker.com/engine/tutorials/dockervolumes/)).

For more about Redis persistence, see [the official Redis documentation](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/).

### File and Directory Permissions

Redis will attempt to correct the ownership and permissions of the data and configuration (since 8.0.2) directories and files if they are not set correctly. This adjustment is only performed in basic, default scenarios to avoid interfering with custom or user-specific configurations.

You can skip this step by setting the `SKIP_FIX_PERMS=1`(since 8.0.2) environment variable.

### Manually Setting File and Directory Permissions

If you prefer to handle file permissions yourself, you can use a `docker run` command to set the correct ownership on mounted volumes. For example:

```console
$ docker run --rm -v /your/host/path:/data redis chown -R redis:redis /data
```

## Connecting via `redis-cli`

```console
$ docker run -it --network some-network --rm redis redis-cli -h some-redis
```

## Additionally, if you want to use your own redis.conf ...

You can create your own Dockerfile that adds a redis.conf from the context into /data/, like so.

```dockerfile
FROM redis
COPY redis.conf /usr/local/etc/redis/redis.conf
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
```

Alternatively, you can specify something along the same lines with `docker run` options.

```console
$ docker run -v /myredis/conf:/usr/local/etc/redis --name myredis redis redis-server /usr/local/etc/redis/redis.conf
```

Where `/myredis/conf/` is a local directory containing your `redis.conf` file. Using this method means that there is no need for you to have a Dockerfile for your redis container.

The mapped directory should be writable, as depending on the configuration and mode of operation, Redis may need to create additional configuration files or rewrite existing ones.

# Image Variants

The `redis` images come in many flavors, each designed for a specific use case.

## `redis:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like bookworm or trixie in them. These are the suite code names for releases of [Debian](https://wiki.debian.org/DebianReleases) and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

## `redis:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

Starting with Redis 8.0, Redis follows a tri-licensing model with the choice of the [Redis Source Available License v2 - RSALv2](https://redis.io/legal/rsalv2-agreement/), [Server Side Public License v1 - SSPLv1](https://redis.io/legal/server-side-public-license-sspl/), or the [GNU Affero General Public License v3 - AGPLv3](https://opensource.org/license/agpl-v3). Prior versions of Redis (<=7.2.4) are licensed under [3-Clause BSD](https://opensource.org/license/bsd-3-clause)⁠, and Redis 7.4.x-7.8.x are licensed under the dual [RSALv2](https://redis.io/legal/rsalv2-agreement/) or [SSPLv1](https://redis.io/legal/server-side-public-license-sspl/) license.

Please also view the [Redis License Overview](https://redis.io/legal/licenses/) and the [Redis Trademark Policy](https://redis.io/legal/trademark-policy/).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `redis/` directory](https://github.com/docker-library/repo-info/tree/master/repos/redis).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
