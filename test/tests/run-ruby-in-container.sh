#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/ruby"
cmd=( ruby "$inContainerPath/container.rb" )

if ! ret="$(docker run --rm -v "$dir":"$inContainerPath":ro "$1" "${cmd[@]}")"; then
	echo >&2 "error: '"$(basename "$dir")"' failed! got $ret"
	exit 1
fi
if [ -f "$dir/expected-std-out.txt" ]; then
	comparison="$(echo -n "$ret" | diff -q "$dir/expected-std-out.txt" -)"
	echo "$comparison"
	#echo >&2 "error: expected 'ok', got '$ret'"
	#exit 1
fi
