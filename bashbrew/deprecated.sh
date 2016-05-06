#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
cmd="$(basename "$0" '.sh')"

echo >&2 "warning: '$0' is deprecated, and '$dir/bashbrew.sh $cmd' should be used directly instead"

exec "$dir/bashbrew.sh" "$cmd" "$@"
