#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Pull a client image with curl for testing
clientImage='buildpack-deps:jessie-curl'
docker pull "$clientImage"

# Create an instance of the container-under-test
cid="$(docker run -d -v "$dir/index.jsp":/var/lib/jetty/webapps/ROOT/index.jsp:ro "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

# RACY TESTS ARE RACY
sleep 1
# TODO find a cleaner solution to this, similar to what we do in mysql-basics

_request() {
	local method="$1"

	local url="${2#/}"

	docker run --rm -i --link "$cid":jetty \
		"$clientImage" -fsSL -X"$method" "http://jetty:8080/$url"
}

# Check that we can request /index.jsp with no params
[ "$(_request GET "/" | tail -1)" = "null" ]

# Check that our index.jsp echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(_request GET "/?hello=$hello" | tail -1)" = "$hello" ]
