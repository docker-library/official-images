<!--

********************************************************************************

WARNING:

    DO NOT EDIT "varnish/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "varnish/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[the Varnish Docker Community](https://github.com/varnish/docker-varnish)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`fresh`, `latest`, `9.0.3-4`, `9.0.3`, `9.0`, `9`](https://github.com/varnish/docker-varnish/blob/842b01df2dac66c086071cb238f4eac5c319cc36/fresh/debian/Dockerfile)

-	[`old`, `8.0.2-1`, `8.0.2`, `8.0`, `8`](https://github.com/varnish/docker-varnish/blob/40cfe05d7eba91c1d6588f9bb40ed64ee84312fe/old/debian/Dockerfile)

-	[`old-alpine`, `8.0.2-alpine`, `8.0-alpine`, `8-alpine`](https://github.com/varnish/docker-varnish/blob/40cfe05d7eba91c1d6588f9bb40ed64ee84312fe/old/alpine/Dockerfile)

-	[`stable`, `6.0.18-1`, `6.0.18`, `6.0`, `6`](https://github.com/varnish/docker-varnish/blob/c9eabe6cdbfbf5f5c2ee9959f42d926cbcc234c1/stable/debian/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/varnish/docker-varnish/issues](https://github.com/varnish/docker-varnish/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/varnish/), [`arm64v8`](https://hub.docker.com/r/arm64v8/varnish/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/varnish/` directory](https://github.com/docker-library/repo-info/blob/master/repos/varnish) ([history](https://github.com/docker-library/repo-info/commits/master/repos/varnish))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/varnish` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Fvarnish)  
	[official-images repo's `library/varnish` file](https://github.com/docker-library/official-images/blob/master/library/varnish) ([history](https://github.com/docker-library/official-images/commits/master/library/varnish))

-	**Source of this description**:  
	[docs repo's `varnish/` directory](https://github.com/docker-library/docs/tree/master/varnish) ([history](https://github.com/docker-library/docs/commits/master/varnish))

# What is Varnish?

Varnish is an HTTP accelerator designed for content-heavy dynamic web sites as well as APIs. In contrast to other web accelerators, such as Squid, which began life as a client-side cache, or Apache and nginx, which are primarily origin servers, Varnish was designed as an HTTP accelerator. Varnish is focused exclusively on HTTP, unlike other proxy servers that often support FTP, SMTP and other network protocols.

> [wikipedia.org/wiki/Varnish_(software)](https://en.wikipedia.org/wiki/Varnish_(software))

![logo](https://raw.githubusercontent.com/docker-library/docs/5ca8e315af01e76381d499a2928f7f47a6787f49/varnish/logo.png)

# How to use this image.

```console
$ docker run -p 8080:80 --ulimit memlock=-1:-1 --tmpfs /var/lib/varnish/varnishd:exec varnish
```

You can then visit [http://localhost:8080](http://localhost:8080) with your browser and be greeted by the default landing page.

**Note:** while the `--ulimit` and `--tmpfs` options aren't necessary, they are greatly recommended. More details are available at the end of this page.

## Basic usage

### Simple cache

The default Varnish configuration will read the `VARNISH_BACKEND_HOST` environment variable which should be an HTTP or HTTPS URL, for example:

```console
$ docker run \
	--ulimit memlock=-1:-1 \
	--tmpfs /var/lib/varnish/varnishd:exec \
	-p 8080:80 \
	-e VARNISH_BACKEND_HOST=https://example.com/ \
	varnish
```

By default, Varnish is extremely careful regarding what it can and cannot cache by looking at the [client request](https://www.varnish-software.com/developers/tutorials/varnish-builtin-vcl/#1-vcl_recv) and at the [backend response](https://www.varnish-software.com/developers/tutorials/varnish-builtin-vcl/#11-vcl_backend_response).

Notably, Varnish will not cache if:

-	the request is not a `GET` or `HEAD`
-	the request contains an `Authorization` or `Cookie` header
-	the response status is not cacheable (i.e., not a 2xx or 4xx response)
-	the response contains a `Set-Cookie` header
-	the response contains headers indicating it is uncacheable

These rules can, of course, be overridden by providing your own `VCL` file, as explained in the next section.

### Custom caching logic

If you already have a VCL file, you can directly mount it as `/etc/varnish/default.vcl`:

```console
$ docker run \
	--ulimit memlock=-1:-1 \
	--tmpfs /var/lib/varnish/varnishd:exec \
	-p 8080:80 \
	-v /path/to/default.vcl:/etc/varnish/default.vcl:ro \
	varnish
```

Alternatively, a simple `Dockerfile` can be used to generate a new image that includes the necessary `default.vcl`:

```dockerfile
FROM varnish

COPY default.vcl /etc/varnish/
```

Place this file in the same directory as your `default.vcl`, run `docker build -t my-varnish .`, then start your container:

```console
$ docker \
	--ulimit memlock=-1:-1 \
	--tmpfs /var/lib/varnish/varnishd:exec \
	-p 8080:80 \
	my-varnish
```

## Reloading the configuration

The images all ship with [varnishreload](https://github.com/varnish/all-packager/blob/809d3c098d1cb84d1b85e18573121a3a3720c898/varnish/systemd/varnishreload#L48-L82) which allows you to easily update the running configuration without restarting the container (and therefore losing your cache). At its most basic, you just need this:

```console
# update the default.vcl in your container
docker cp new_default.vcl running_container:/etc/varnish/default.vcl
# run varnishreload
docker exec running_container varnishreload
```

Note that `varnishreload` also supports reloading other files (it doesn't have to be `default.vcl`), labels (`-l`), and garbage collection of old labels (`-m`), among others. To learn more, run

```console
$ docker run --rm varnish varnishreload -h
```

## File server

Using the included [vmod-fileserver](https://github.com/varnish-rs/vmod-fileserver), Varnish can be used as a file server. Just mount the directory you want to expose into the `/var/www/html` directory and set the `VARNISH_FILESERVER` variable to `true`:

```console
$ docker run \
	--ulimit memlock=-1:-1 \
	--tmpfs /var/lib/varnish/varnishd:exec \
	-p 8080:80 \
	-v /dir/to/expose:/var/www/html:ro \
	-e VARNISH_FILESERVER=true \
	varnish
```

**Note:** Varnish will reply with an empty 200 when trying to access folders instead of individual files.

## Environment variables

### Backend address (`VARNISH_BACKEND_HOST`)

Set the backend address and protocol as explained above. This only works with the provided `VCL`, i.e. if you don't mount an `/etc/varnish/default.vcl` file, and if you don't set `VARNISH_VCL_FILE`

### File server mode (`VARNISH_FILESERVER`)

Also only valid with the default `VCL`. If `VARNISH_BACKEND_HOST` is unset and `VARNISH_FILESERVER` is set, Varnish will act as a server, using `/var/www/html` as its source.

### Cache size (`VARNISH_SIZE`)

By default, the containers will use a cache size of 100MB, which is usually a bit too small, but you can quickly set it through the `VARNISH_SIZE` environment variable:

```console
$ docker run --tmpfs /var/lib/varnish/varnishd:exec -p 8080:80 -e VARNISH_SIZE=2G varnish
```

### Listening ports (`VARNISH_HTTP_PORT`/`VARNISH_PROXY_PORT`)

Varnish will listen to HTTP traffic on port `80`, and this can be overridden by setting the environment variable `VARNISH_HTTP_PORT`. Similarly, the variable `VARNISH_PROXY_PORT` (defaulting to `8443`) dictates the listening port for the [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) used notably to interact with [hitch](https://hub.docker.com/_/hitch) (which, coincidentally, uses `8443` as a default too!).

```console
# instruct varnish to listen on port 7777 instead of 80
$ docker run --tmpfs /var/lib/varnish/varnishd:exec -p 8080:7777 -e VARNISH_HTTP_PORT=7777 varnish
```

### VCL file (`VARNISH_VCL_FILE`)

The default Varnish configuration file is `/etc/varnish/default.vcl`, but this can be overridden with the `VARNISH_VCL_FILE` environment variable. This is useful if you want a single image that can be deployed with different configurations baked in it.

### Extra arguments

Additionally, you can add arguments to `docker run` after `varnish`, if the first argument starts with a `-`, the whole list will be appended to the [default command](https://github.com/varnish/docker-varnish/blob/master/fresh/debian/scripts/docker-varnish-entrypoint):

```console
# extend the default keep period
$ docker run \
	--ulimit memlock=-1:-1 \
	--tmpfs /var/lib/varnish/varnishd:exec \
	-p 8080:80 \
	varnish -p default_keep=300
```

If your first argument after `varnish` doesn't start with `-`, it will be interpreted as a command to override the default one:

```console
# show the command-line options
$ docker run varnish varnishd -?

# list parameters usable with -p
$ docker run varnish varnishd -x parameter

# run the server with your own parameters (don't forget -F to not daemonize)
$ docker run varnish varnishd -F -a :8080 -b 127.0.0.1:8181 -t 600 -p feature=+http2
```

This can notably be used to extract logs using [varnishncsa or varnishlog](https://www.varnish-software.com/developers/tutorials/vsl-cheatsheet/), running `varnishstat -1` to extract metrics, and of course reloading the `VCL` with `varnishreload`.

## Vmods

The docker image is built with a collection of "`VCL` modules" or "vmods" that extend Varnish capability. We've already covered `vmod-fileserver` (file backend) and `vmod-reqwest` (dynamic backends), but more are available and can be used in your custom `VCL` with `import <vmod_name>`. Please refer to the documentation of each vmod for more information.

# ulimit and tmpfs notes

Varnish uses [memory-mapped files](https://docs.varnish-software.com/varnish-enterprise/installation/#the-shared-memory-log) to log and store metrics for performance reasons. Those files are constantly written to, and to get the most out of your system, you should:

-	mount the working directory as `tmpfs` to make sure disk I/O isn't a bottleneck; that's what the `--tmpfs` switch does
-	allow Varnish to lock those memory-mapped files so they aren't paged out by the kernel; hence the `--ulimit` switch

# Image Variants

The `varnish` images come in many flavors, each designed for a specific use case.

## `varnish:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `varnish:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://github.com/varnishcache/varnish-cache/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `varnish/` directory](https://github.com/docker-library/repo-info/tree/master/repos/varnish).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
