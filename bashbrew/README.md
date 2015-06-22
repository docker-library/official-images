# Bashbrew

The recommended way to use `bashbrew.sh` is to install a symlink in your `PATH` somewhere as `bashbrew`, for example `~/bin/bashbrew -> /path/to/official-images/bashbrew/bashbrew.sh` (assuming `~/bin` is in `PATH`).

```console
$ bashbrew --help

usage: bashbrew [build|push|list] [options] [repo[:tag] ...]
   ie: bashbrew build --all
       bashbrew push debian ubuntu:12.04
       bashbrew list --namespaces='_' debian:7 hello-world

This script processes the specified Docker images using the corresponding
repository manifest files.

common options:
  --all              Build all repositories specified in library
  --docker="docker"
                     Use a custom Docker binary
  --retries="4"
                     How many times to try again if the build/push fails before
                     considering it a lost cause (always attempts a minimum of
                     one time, but maximum of one plus this number)
  --help, -h, -?     Print this help message
  --library="/home/tianon/docker/stackbrew/library"
                     Where to find repository manifest files
  --logs="/home/tianon/docker/stackbrew/bashbrew/logs"
                     Where to store the build logs
  --namespaces="_"
                     Space separated list of image namespaces to act upon
                     
                     Note that "_" is a special case here for the unprefixed
                     namespace (ie, "debian" vs "library/debian"), and as such
                     will be implicitly ignored by the "push" subcommand
                     
                     Also note that "build" will always tag to the unprefixed
                     namespace because it is necessary to do so for dependent
                     images to use FROM correctly (think "onbuild" variants that
                     are "FROM base-image:some-version")
  --uniq
                     Only process the first tag of identical images
                     This is not recommended for build or push
                     i.e. process python:2.7, but not python:2

build options:
  --no-build         Don't build, print what would build
  --no-clone         Don't pull/clone Git repositories
  --src="/home/tianon/docker/stackbrew/bashbrew/src"
                     Where to store cloned Git repositories (GOPATH style)

push options:
  --no-push          Don't push, print what would push

```

## Subcommands

### `bashbrew build`

This script reads the library files for the images specified and then clones the required Git repositories into the specified `--src` directory. If the Git repository already exists, the script verifies that the Git ref specified in the library file exists and does `git fetch` as necessary.

The next step in the script is to build each image specified. All the `image:tag` combinations are placed into a queue. The processing order is determined by the order of items passed in on the command line (or alphabetical if `--all` is used). When a whole image, like `debian`, is specified the `image:tag` combinations are added to the queue in the order that they appear in the library file. For each `image:tag` to be processed, the system checks out the specified commit and sets mtimes (see [`git-set-mtimes`](#git-set-mtimes)) of all files in the Git repository to take advantage of Docker caching. If the `image:tag` is `FROM` another image that is later in the queue, it is deferred to the end of the queue.

After the image is built, the final step of the script is to tag the image into each of the given `--namespaces`.

The `--no-clone` option skips the `git clone` step and will cause the script to fail on the build step if the Git repository does not exist or is missing the required Git refs.

The `--no-build` option skips all the building, including setting the mtimes.

**WARNING:** setting `--src` so that it uses a local working copy of your Git directory for a specified build will delete untracked and uncommitted changes, and will disable `gc.auto`. It is not recommended to symlink in your working directories for use during build.

### `bashbrew push`

This script takes advantage of `docker login` and does a `docker push` on each `image:tag` specified for the given `--namespaces`. The script will warn if a given `namespace/image:tag` does not exist.

The `--no-push` option prints out the `docker push` instructions that would have been executed.

### `bashbrew list`

Takes the same arguments as `bashbrew build` and `bashbrew push`, but prints a list of image names and quits.

For example:

```console
$ # count the number of tags in the official library
$ bashbrew list --all | wc -l
802
$ # count the number of _unique_ tags in the official library
$ bashbrew list --all --uniq | wc -l
296

$ # pull all officially supported tags of "debian"
$ bashbrew list debian | xargs -n1 --verbose docker pull
...

$ # list all unique supported tags of "python"
$ bashbrew list --uniq python
python:2.7.10
python:2.7.10-onbuild
python:2.7.10-slim
python:2.7.10-wheezy
python:3.2.6
python:3.2.6-onbuild
python:3.2.6-slim
python:3.2.6-wheezy
python:3.3.6
python:3.3.6-onbuild
python:3.3.6-slim
python:3.3.6-wheezy
python:3.4.3
python:3.4.3-onbuild
python:3.4.3-slim
python:3.4.3-wheezy
```

## Helper Scripts

### `git-set-mtimes`

Since Docker caching of layers is based upon the mtimes of files and folders, this script sets each file's mtime to the time of the commit that most recently modified it and sets each directory's mtime to be the most recent mtime of any file or folder contained within it. This gives a deterministic time for all files and folders in the Git repository.
