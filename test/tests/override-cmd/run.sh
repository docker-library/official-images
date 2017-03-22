#!/bin/bash
set -eo pipefail

image="$1"

# test that we can override the CMD with echo
# https://github.com/docker-library/official-images/blob/d28cb89e79417cac50c2a8ae163a9b3b79167f79/README.md#consistency

hello="world-$RANDOM-$RANDOM"

# test first with --entrypoint to verify that we even have echo (tests for single-binary images FROM scratch, essentially)
if ! testOutput="$(docker run --rm --entrypoint echo "$image" "Hello $hello" 2>/dev/null)"; then
	echo >&2 'image does not appear to contain "echo" -- assuming single-binary image'
	exit
fi
[ "$testOutput" = "Hello $hello" ]

# now test with normal command to verify the default entrypoint is OK
output="$(docker run --rm "$image" echo "Hello $hello")"
[ "$output" = "Hello $hello" ]
