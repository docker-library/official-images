#!/bin/bash
set -e

if ! docker run --rm --entrypoint bash "$1" -c 'true' &> /dev/null; then
	# die quietly and gracefully if this image doesn't have bash at all
	exit 0
fi

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
source "$dir/really-run.sh" "$@"
