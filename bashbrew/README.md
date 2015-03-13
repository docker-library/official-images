# Bashbrew

## Main Scripts

### `build.sh`

```console
$ ./bashbrew/build.sh --help

usage: ./bashbrew/build.sh [options] [repo[:tag] ...]
   ie: ./bashbrew/build.sh --all
       ./bashbrew/build.sh debian ubuntu:12.04

   This script builds the Docker images specified using the Git repositories
   specified in the library files.

options:
  --help, -h, -?     Print this help message
  --all              Builds all Docker repos specified in library
  --no-clone         Don't pull the Git repos
  --no-build         Don't build, just echo what would have built
  --library="./stackbrew/library"
                     Where to find repository manifest files
  --src="./stackbrew/bashbrew/src"
                     Where to store the cloned Git repositories
  --logs="./stackbrew/bashbrew/logs"
                     Where to store the build logs
  --namespaces="library stackbrew"
                     Space separated list of namespaces to tag images in after
                     building
```

This script reads the library files for the images specified and then clones the required Git repositories into the specified `--src` directory. If the Git repository already exists, the script verifies that the Git ref specified in the library file exists and does `git fetch` as necessary.

The next step in the script is to build each image specified. All the `image:tag` combinations are placed into a queue. The processing order is determined by the order of items passed in on the command line (or alphabetical if `--all` is used). When a whole image, like `debian`, is specified the `image:tag` combinations are added to the queue in the order that they appear in the library file. For each `image:tag` to be processed, the system checks out the specified commit and sets mtimes (see [`git-set-mtimes`](#git-set-mtimes)) of all files in the Git repository to take advantage of Docker caching. If the `image:tag` is `FROM` another image that is later in the queue, it is deferred to the end of the queue.

After the image is built, the final step of the script is to tag the image into each of the given `--namespaces`.

The `--no-clone` option skips the `git clone` step and will cause the script to fail on the build step if the Git repository does not exist or is missing the required Git refs.

The `--no-build` option skips all the building, including setting the mtimes.

**WARNING:** setting `--src` so that it uses a local working copy of your Git directory for a specified build will delete untracked and uncommitted changes, and will disable `gc.auto`. It is not recommended to symlink in your working directories for use during build.

### `push.sh`

```console
$ ./bashbrew/push.sh --help

usage: ./bashbrew/push.sh [options] [repo[:tag] ...]
   ie: ./bashbrew/push.sh --all
       ./bashbrew/push.sh debian ubuntu:12.04

   This script pushes the specified Docker images from library that are built
   and tagged in the specified namespaces.

options:
  --help, -h, -?     Print this help message
  --all              Pushes all Docker images built for the given namespaces
  --no-push          Don't actually push the images to the Docker Hub
  --library="./stackbrew/library"
                     Where to find repository manifest files
  --namespaces="library stackbrew"
                     Space separated list of namespaces to tag images in after
                     building
```

This script takes advantage of `docker login` and does a `docker push` on each `image:tag` specified for the given `--namespaces`. The script will warn if a given `namespace/image:tag` does not exist.

The `--no-push` option prints out the `docker push` instructions that would have been executed.

## Helper Scripts

### `git-set-mtimes`

Since Docker caching of layers is based upon the mtimes of files and folders, this script sets each file's mtime to the time of the commit that most recently modified it and sets each directory's mtime to be the most recent mtime of any file or folder contained within it. This gives a deterministic time for all files and folders in the Git repository.
