#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/python"
cmd=( "$inContainerPath/container.py" )

docker run --rm -v "$dir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint sh "$1" -ec '
	for c in python3 python pypy3 pypy; do
		if command -v "$c" > /dev/null; then
			exec "$c" "$@"
		fi
	done
	echo >&2 "error: unable to determine how to run python"
	exit 1
' -- "${cmd[@]}"
