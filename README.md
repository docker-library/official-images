# About this Repo

[![Docker Stars](https://img.shields.io/docker/stars/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Docker Pulls](https://img.shields.io/docker/pulls/_/elixir.svg?style=flat-square)](https://hub.docker.com/_/elixir/)
[![Image Layers](https://badge.imagelayers.io/elixir:latest.svg)](https://imagelayers.io/?images=elixir:latest 'Show Image Layers at imagelayers.io')

[![Build Status](https://travis-ci.org/c0b/docker-elixir.svg?branch=master)](https://travis-ci.org/c0b/docker-elixir)

This is for elixir latest stable image and next -dev image.

```console
REPOSITORY TAG           IMAGE ID            CREATED             SIZE
elixir     v1.5.0-dev-b3e6c54    8948fc7adc11        11 minutes ago      755 MB
elixir     v1.4.0-rc.1-slim      0c49845329c2        29 minutes ago      292.4 MB
elixir     v1.4.0-rc.1           a50b16247e14        32 minutes ago      757 MB
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
iex(2)> OptionParser.parse(["--verbose", "-v", "-v"], switches: [verbose: :count], aliases: [v: :verbose])
{[verbose: 3], [], []}
iex(3)> {opts, _, _} = v(2)
{[verbose: 3], [], []}
iex(4)> OptionParser.to_argv(opts, switches: [verbose: :count])
["--verbose", "--verbose", "--verbose"]
iex(5)>
```

## How to get the latest elixir

All the elixir's upstream stable versions are pushed over docker official hub
(https://hub.docker.com/_/elixir/), while rc images and the latest development version are not;
Like this 1.5.0-dev image, if you want to get the latest bleeding edge elixir code
from master branch, you may get its git commit id (https://github.com/elixir-lang/elixir/)
and sha256, modify the 1.5/Dockerfile locally and build it:

```console
$ docker build -t elixir:1.5.0-dev ./1.5
[...]
```
