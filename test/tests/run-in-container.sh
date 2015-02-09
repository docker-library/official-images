#!/bin/bash
set -e

# NOT INTENDED TO BE USED AS A TEST "run.sh" DIRECTLY
# SEE OTHER "run-*-in-container.sh" SCRIPTS FOR USAGE

testDir="$1"
shift
inContainerPath="/tmp/test-dir"

image="$1"
shift
entrypoint="$1"
shift

exec docker run --rm -v "$testDir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint "$entrypoint" "$image" "$@"
