# About this Repo

[![Docker Stars](https://img.shields.io/docker/stars/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Docker Pulls](https://img.shields.io/docker/pulls/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Image Layers](https://badge.imagelayers.io/elixir:latest.svg)](https://imagelayers.io/?images=elixir:latest 'Show Image Layers at imagelayers.io')

[![Build Status](https://travis-ci.org/c0b/docker-elixir.svg?branch=master)](https://travis-ci.org/c0b/docker-elixir)

This is for elixir latest stable image and next -dev image.

```console
➸ docker images
REPOSITORY  TAG   IMAGE ID       CREATED             SIZE
elixir      1.2   fcc8b4432e3e   About a minute ago  290.2 MB
elixir      1.3   5c67fece33fb   7 minutes ago       290.3 MB
```

```console
➸ docker run -it --rm elixir:v1.3.0-rc.0
Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.3.0-rc.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> System.version
"1.3.0-rc.0"
iex(2)> OptionParser.parse(["--verbose", "-v", "-v"], switches: [verbose: :count], aliases: [v: :verbose])
{[verbose: 3], [], []}
```
