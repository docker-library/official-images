# Bashbrew (`bashbrew`)

[![Jenkins Build Status](https://doi-janky.infosiftr.net/job/bashbrew/badge/icon)](https://doi-janky.infosiftr.net/job/bashbrew/)

```console
$ bashbrew --help
NAME:
   bashbrew - canonical build tool for the official images

USAGE:
   bashbrew [global options] command [command options] [arguments...]

COMMANDS:
     list, ls    list repo:tag combinations for a given repo
     build       build (and tag) repo:tag combinations for a given repo
     tag         tag repo:tag into a namespace (especially for pushing)
     push        push namespace/repo:tag (see also "tag")
     put-shared  update shared tags in the registry (and multi-architecture tags)
     help, h     Shows a list of commands or help for one command
   plumbing:
     children, offspring, descendants, progeny  print the repos built FROM a given repo or repo:tag
     parents, ancestors, progenitors            print the repos this repo or repo:tag is FROM
     cat                                        print manifest contents for repo or repo:tag
     from                                       print FROM for repo:tag

GLOBAL OPTIONS:
   --debug                  enable more output (esp. all "docker build" output instead of only output on failure) [$BASHBREW_DEBUG]
   --no-sort                do not apply any sorting, even via --build-order
   --arch value             the current platform architecture (default: "amd64") [$BASHBREW_ARCH]
   --constraint value       build constraints (see Constraints in Manifest2822Entry) [$BASHBREW_CONSTRAINTS]
   --exclusive-constraints  skip entries which do not have Constraints
   --arch-namespace value   architecture to push namespace mappings for creating indexes/manifest lists ("arch=namespace" ala "s390x=tianons390x") [$BASHBREW_ARCH_NAMESPACES]
   --config value           where default "flags" configuration can be overridden more persistently (default: "/home/tianon/.config/bashbrew") [$BASHBREW_CONFIG]
   --library value          where the bodies are buried (default: "/home/tianon/docker/official-images/library") [$BASHBREW_LIBRARY]
   --cache value            where the git wizardry is stashed (default: "/home/tianon/.cache/bashbrew") [$BASHBREW_CACHE]
   --help, -h, -?           show help
```

## Installing

Pre-built binaries are available to [download from Jenkins (for a large variety of supported architectures)](https://doi-janky.infosiftr.net/job/bashbrew/lastSuccessfulBuild/artifact/bin/).

For building `bashbrew` yourself, there are clues in [`bashbrew.sh`](bashbrew.sh) and [`.travis.yml`](../.travis.yml) (although it's a pretty standard Go application).

## Usage

Docker version 1.10 or above is required for use of Bashbrew.

In general, `bashbrew build some-repo` or `bashbrew build ./some-file` should be sufficient for using the tool at a surface level, especially for testing. For more complex usage, please see the built-in help (`bashbrew --help`, `bashbrew build --help`, etc).

## Configuration

The default "flags" configuration is in `~/.config/bashbrew/flags`, but the base path can be overridden with `--config` or `BASHBREW_CONFIG` (technically, the full path to the `flags` configuration file is `${BASHBREW_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/bashbrew}/flags`).

To set a default namespace for specific commands only:

```
Commands: tag, push
Namespace: officialstaging
```

To set a default namespace for all commands:

```
Namespace: jsmith
```

A more complex example:

```
# comments are allowed anywhere (and are ignored)
Library: /mnt/docker/official-images/library
Cache: /mnt/docker/bashbrew-cache
Constraints: aufs, docker-1.9, tianon
ExclusiveConstraints: true

# namespace just "tag" and "push" (not "build")
Commands: tag, push
Namespace: tianon

Commands: list
ApplyConstraints: true

Commands: tag
Debug: true
```

In this example, `bashbrew tag` will get both `Namespace` and `Debug` applied.
