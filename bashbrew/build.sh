#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

exec "$dir/bashbrew.sh" build "$@"
