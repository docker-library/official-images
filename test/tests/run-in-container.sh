#!/bin/bash
set -e

# NOT INTENDED TO BE USED AS A TEST "run.sh" DIRECTLY
# SEE OTHER "run-*-in-container.sh" SCRIPTS FOR USAGE

testDir="$1"
shift

image="$1"
shift
entrypoint="$1"
shift

# do some fancy footwork so that if testDir is /a/b/c, we mount /a/b and use c as the working directory (so relative symlinks work one level up)
testDir="$(readlink -f "$testDir")"
hostMount="$(dirname "$testDir")"
containerMount="/tmp/test-dir"
workdir="$containerMount/$(basename "$testDir")"
# TODO should we be doing something fancy with $BASH_SOURCE instead so we can be arbitrarily deep and mount the top level always?

exec docker run --rm -v "$hostMount":"$containerMount":ro -w "$workdir" --entrypoint "$entrypoint" "$image" "$@"
