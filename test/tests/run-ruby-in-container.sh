#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/ruby"
cmd=( "$inContainerPath/container.rb" )

if ! ret="$(docker run --rm -v "$dir":"$inContainerPath":ro --entrypoint ruby "$1" "${cmd[@]}")"; then
	echo >&2 "error: '"$(basename "$dir")"' failed! got $ret"
	exit 1
fi

if [ -f "$dir/expected-std-out.txt" ] && ! echo "$ret" | diff "$dir/expected-std-out.txt" - &> /dev/null; then
	echo >&2 "error: expected '$(cat "$dir/expected-std-out.txt")', got '$ret'"
	exit 1
fi
