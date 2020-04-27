#!/usr/bin/env bash
set -Eeuo pipefail

image="$1"

# test that we can override the CMD with echo
# https://github.com/docker-library/official-images/blob/d28cb89e79417cac50c2a8ae163a9b3b79167f79/README.md#consistency

hello="world-$RANDOM-$RANDOM"

cmd=( echo "Hello $hello" )
case "$image" in
	*windowsservercore* | *nanoserver*)
		cmd=( cmd /Q /S /C "${cmd[*]}" )
		;;
esac

# test first with --entrypoint to verify that we even have echo (tests for single-binary images FROM scratch, essentially)
if ! testOutput="$(docker run --rm --entrypoint "${cmd[0]}" "$image" "${cmd[@]:1}" 2>/dev/null)"; then
	echo >&2 'image does not appear to contain "echo" -- assuming single-binary image'
	exit
fi
testOutput="$(tr -d '\r' <<<"$testOutput")" # Windows gives us \r\n ...  :D
[ "$testOutput" = "Hello $hello" ]

# now test with normal command to verify the default entrypoint is OK
output="$(docker run --rm "$image" "${cmd[@]}")"
output="$(tr -d '\r' <<<"$output")" # Windows gives us \r\n ...  :D
[ "$output" = "Hello $hello" ]
