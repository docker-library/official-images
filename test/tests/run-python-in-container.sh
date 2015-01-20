#!/bin/bash
set -e

python="$(docker run --rm "$1" bash -ec '
	for c in python3 python pypy3 pypy; do
		if command -v "$c" &> /dev/null; then
			echo "$c"
			break
		fi
	done
')"

if [ -z "$python" ]; then
	echo >&2 "error: unable to determine how to run 'python' in '$1'"
	exit 1
fi

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/python"
cmd=( "$python" "$inContainerPath/container.py" )

if ! ret="$(docker run --rm -e PYTHON="$python" -v "$dir":"$inContainerPath":ro "$1" "${cmd[@]}")"; then
	echo >&2 "error: '"$(basename "$dir")"' failed! got $ret"
	exit 1
fi

if [ -f "$dir/expected-std-out.txt" ] && ! echo "$ret" | diff "$dir/expected-std-out.txt" - &> /dev/null; then
	echo >&2 "error: expected '$(cat "$dir/expected-std-out.txt")', got '$ret'"
	exit 1
fi
