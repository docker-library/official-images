#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image since it should already have curl
clientImage="$image"

# Create an instance of the container-under-test
cid="$(docker run -d -v "$dir/index.jsp":/var/lib/jetty/webapps/ROOT/index.jsp:ro "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":jetty "$clientImage" \
		curl -fs -X"$method" "$@" "http://jetty:8080/$url"
}

# Make sure that Jetty is listening on port 8080
retry --tries 40 --sleep 0.25 '[ "$(_request GET / --output /dev/null || echo $?)" = 7 ]'

# Check that we can request /index.jsp with no params
[ "$(_request GET "/" | tail -1)" = "null" ]

# Check that our index.jsp echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(_request GET "/?hello=$hello" | tail -1)" = "$hello" ]
