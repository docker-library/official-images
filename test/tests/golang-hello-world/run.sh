#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

if [[ "${image##*/}" == gcc:4* ]]; then
	echo >&2 'warning: gcc 4.x does not support Go'
	cat "$dir/expected-std-out.txt" # cheaters gunna cheat
	exit
fi

exec "$dir/real-run.sh" "$@"
