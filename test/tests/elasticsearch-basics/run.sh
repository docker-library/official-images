#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image since it should already have curl
clientImage="$image"

# Create an instance of the container-under-test
cid="$(docker run -d "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":es "$clientImage" \
		curl -fs -X"$method" "$@" "http://es:9200/$url"
}

# Make sure our container is listening
. "$dir/../../retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Perform simple health check
[ "$(_request GET / | awk -F '[:",[:space:]]+' '$2 == "tagline" { $1 = $2 = ""; print }')" = '  You Know for Search ' ]

# TODO perform some simple operations and make sure things are actually working
