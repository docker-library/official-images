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

# run each test artifact in a separate, isolated container
for artifact in "$(dirname "$(readlink -f "$BASH_SOURCE")")"/python-artifacts/*; do
	inContainerPath="/tmp/$(basename "$artifact")"
	case "$artifact" in
		*.py) cmd=( "$python" "$inContainerPath" ) ;;
		*.sh) cmd=( "$inContainerPath" ) ;;
		*)    continue ;;
	esac
	if ! docker run --rm -e PYTHON="$python" -v "$artifact":"$inContainerPath":ro "$1" "${cmd[@]}"; then
		echo >&2 "error: '$artifact' failed!"
		exit 1
	fi
done
