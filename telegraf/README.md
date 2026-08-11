<!--

********************************************************************************

WARNING:

    DO NOT EDIT "telegraf/README.md"

    IT IS AUTO-GENERATED

    (from the other files in "telegraf/" combined with a set of templates)

********************************************************************************

-->

# Quick reference

-	**Maintained by**:  
	[InfluxData](https://github.com/influxdata/influxdata-docker)

-	**Where to get help**:  
	[the Docker Community Slack](https://dockr.ly/comm-slack), [Server Fault](https://serverfault.com/help/on-topic), [Unix & Linux](https://unix.stackexchange.com/help/on-topic), or [Stack Overflow](https://stackoverflow.com/help/on-topic)

# Supported tags and respective `Dockerfile` links

-	[`1.37`, `1.37.3`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.37/Dockerfile)

-	[`1.37-alpine`, `1.37.3-alpine`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.37/alpine/Dockerfile)

-	[`1.38`, `1.38.4`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.38/Dockerfile)

-	[`1.38-alpine`, `1.38.4-alpine`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.38/alpine/Dockerfile)

-	[`1.39`, `1.39.3`, `latest`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.39/Dockerfile)

-	[`1.39-alpine`, `1.39.3-alpine`, `alpine`](https://github.com/influxdata/influxdata-docker/blob/a2353390bbaca5b5b987453c2fe10fe38d2d8aab/telegraf/1.39/alpine/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:  
	[https://github.com/influxdata/influxdata-docker/issues](https://github.com/influxdata/influxdata-docker/issues?q=)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))  
	[`amd64`](https://hub.docker.com/r/amd64/telegraf/), [`arm32v7`](https://hub.docker.com/r/arm32v7/telegraf/), [`arm64v8`](https://hub.docker.com/r/arm64v8/telegraf/)

-	**Published image artifact details**:  
	[repo-info repo's `repos/telegraf/` directory](https://github.com/docker-library/repo-info/blob/master/repos/telegraf) ([history](https://github.com/docker-library/repo-info/commits/master/repos/telegraf))  
	(image metadata, transfer size, etc)

-	**Image updates**:  
	[official-images repo's `library/telegraf` label](https://github.com/docker-library/official-images/issues?q=label%3Alibrary%2Ftelegraf)  
	[official-images repo's `library/telegraf` file](https://github.com/docker-library/official-images/blob/master/library/telegraf) ([history](https://github.com/docker-library/official-images/commits/master/library/telegraf))

-	**Source of this description**:  
	[docs repo's `telegraf/` directory](https://github.com/docker-library/docs/tree/master/telegraf) ([history](https://github.com/docker-library/docs/commits/master/telegraf))

# What is telegraf?

Telegraf is an open source agent for collecting, processing, aggregating, and writing metrics. Based on a plugin system to enable developers in the community to easily add support for additional metric collection. There are five distinct types of plugins:

-	Input plugins collect metrics from the system, services, or 3rd party APIs
-	Output plugins write metrics to various destinations
-	Processor plugins transform, decorate, and/or filter metrics
-	Aggregator plugins create aggregate metrics (e.g. mean, min, max, quantiles, etc.)
-	Secret Store plugins are used to hide secrets from the configuration file

[Telegraf Official Docs](https://docs.influxdata.com/telegraf/latest/get_started/)

![logo](https://raw.githubusercontent.com/docker-library/docs/7b128c7411e3e8375d9639e6455e47874940f012/telegraf/logo.png)

# How to use this image

## Exposed Ports

-	8125 UDP
-	8092 UDP
-	8094 TCP

## Configuration file

The user is required to provide a valid configuration to use the image. A valid configuration has at least one input and one output plugin specified. The following will walk through the general steps to get going.

### Basic Example

Configuration files are TOML-based files that declare which plugins to use. A very simple configuration file, `telegraf.conf`, that collects metrics from the system CPU and outputs the metrics to stdout looks like the following:

```toml
[[inputs.cpu]]
[[outputs.file]]
```

Once a user has a customized configuration file, they can launch a Telegraf container with it mounted in the expected location:

```console
$ docker run -v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf:ro telegraf
```

Modify `$PWD` to the directory where you want to store the configuration file.

Read more about the Telegraf configuration [here](https://docs.influxdata.com/telegraf/latest/administration/configuration/).

### Sample Configuration

Users can generate a sample configuration using the `config` subcommand. This will provide the user with a basic config that has a handful of input plugins enabled that collect data from the system. However, the user will still need to configure at least one output before the file is ready for use:

```console
$ docker run --rm telegraf telegraf config > telegraf.conf
```

## Supported Plugins Reference

The following are links to the various plugins that are available in Telegraf:

-	[Input Plugins](https://docs.influxdata.com/telegraf/latest/plugins/#input-plugins)
-	[Output Plugins](https://docs.influxdata.com/telegraf/latest/plugins/#output-plugins)
-	[Processor Plugins](https://docs.influxdata.com/telegraf/latest/plugins/#processor-plugins)
-	[Aggregator Plugins](https://docs.influxdata.com/telegraf/latest/plugins/#aggregator-plugins)

# Examples

## Monitoring the Docker Engine Host

One common use case for Telegraf is to monitor the Docker Engine Host from within a container. The recommended technique is to mount the host filesystems into the container and use environment variables to instruct Telegraf where to locate the filesystems.

The precise files that need to be made available varies from plugin to plugin. Here is an example showing the full set of supported locations:

```console
$ docker run -d --name=telegraf \
	-v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-v /:/hostfs:ro \
	-e HOST_ETC=/hostfs/etc \
	-e HOST_PROC=/hostfs/proc \
	-e HOST_SYS=/hostfs/sys \
	-e HOST_VAR=/hostfs/var \
	-e HOST_RUN=/hostfs/run \
	-e HOST_MOUNT_PREFIX=/hostfs \
	telegraf
```

## Monitoring docker containers

To monitor other docker containers, you can use the docker plugin and mount the docker socket into the container. An example configuration is below:

```toml
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
```

Then you can start the telegraf container.

```console
$ docker run -d --name=telegraf \
      --net=influxdb \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
      telegraf
```

Refer to the docker [plugin documentation](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/docker/README.md) for more information.

## Install Additional Packages

Some plugins require additional packages to be installed. For example, the `ntpq` plugin requires `ntpq` command. It is recommended to create a custom derivative image to install any needed commands.

As an example this Dockerfile add the `mtr-tiny` image to the stock image and save it as `telegraf-mtr.docker`:

```dockerfile
FROM telegraf:1.12.3

RUN apt-get update && apt-get install -y --no-install-recommends mtr-tiny && \
	rm -rf /var/lib/apt/lists/*
```

Build the derivative image:

```console
$ docker build -t telegraf-mtr:1.12.3 - < telegraf-mtr.docker
```

Create a `telegraf.conf` configuration file:

```toml
[[inputs.exec]]
  interval = "60s"
  commands=["mtr -C -n example.org"]
  timeout = "40s"
  data_format = "csv"
  csv_skip_rows = 1
  csv_column_names=["", "", "status", "dest", "hop", "ip", "loss", "snt", "", "", "avg", "best", "worst", "stdev"]
  name_override = "mtr"
  csv_tag_columns = ["dest", "hop", "ip"]

[[outputs.file]]
  files = ["stdout"]
```

Run your derivative image:

```console
$ docker run --name telegraf --rm -v $PWD/telegraf.conf:/etc/telegraf/telegraf.conf telegraf-mtr:1.12.3
```

# Image Variants

The `telegraf` images come in many flavors, each designed for a specific use case.

## `telegraf:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

## `telegraf:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern. The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions. See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images. Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

# License

View [license information](https://github.com/influxdata/telegraf/blob/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `telegraf/` directory](https://github.com/docker-library/repo-info/tree/master/repos/telegraf).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
