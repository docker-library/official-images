#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/bash"
cmd=( "$inContainerPath/container.sh" )

if ! ret="$(docker run --rm -v "$dir":"$inContainerPath":ro "$1" "${cmd[@]}")"; then
	echo >&2 "error: '"$(basename "$dir")"' failed! got $ret"
	exit 1
fi
if [ -f "$dir/expected-std-out.txt" ]; then
	comparison="$(echo -n "$ret" | diff -q "$dir/expected-std-out.txt" -)"
	# debug ouput
	echo "$comparison"
	# TODO something with the `diff -q` output
	#echo >&2 "error: expected 'ok', got '$ret'"
	#exit 1
fi
