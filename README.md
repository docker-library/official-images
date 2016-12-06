# About this Repo

[![Docker Stars](https://img.shields.io/docker/stars/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Docker Pulls](https://img.shields.io/docker/pulls/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Image Layers](https://badge.imagelayers.io/elixir:latest.svg)](https://imagelayers.io/?images=elixir:latest 'Show Image Layers at imagelayers.io')

[![Build Status](https://travis-ci.org/c0b/docker-elixir.svg?branch=master)](https://travis-ci.org/c0b/docker-elixir)

This is for elixir latest stable image and next -dev image.

```console
REPOSITORY TAG           IMAGE ID            CREATED             SIZE
elixir     1.5.0-dev     590c7a67a318        2 minutes ago       765.3 MB
elixir     1.4.0-rc.0    590c7a67a318        2 minutes ago       765.3 MB
elixir     1.3           9e04e73b74d4        16 minutes ago      766.4 MB
elixir     1.3-slim      7d901dfc3a5e        15 minutes ago      293.9 MB
elixir     1.2           5165c41f0185        6 days ago          773.8 MB
```

```console
➸ docker run -it --rm elixir:v1.5.0-dev
Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.5.0-dev) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> System.version
"1.5.0-dev"
iex(2)> OptionParser.parse(["--verbose", "-v", "-v"], switches: [verbose: :count], aliases: [v: :verbose])
{[verbose: 3], [], []}
iex(3)> OptionParser.parse(["-f", "-43"], strict: [flag: :integer], aliases: [f: :flag])
{[flag: -43], [], []}
```

## How to get the latest elixir

All the elixir's upstream stable versions are pushed over docker official hub
(https://hub.docker.com/_/elixir/), while the latest development version is not;
Like this 1.5.0-dev image, if you want to get the latest bleeding edge elixir code
from master branch, you may get its git commit id (https://github.com/elixir-lang/elixir/)
and sha256, modify the 1.5/Dockerfile locally and build it:

```console
$ docker build -t elixir:1.5.0-dev ./1.5
[...]
```
