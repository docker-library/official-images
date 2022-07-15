#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# Create an instance of the container-under-test
serverImage="$("$dir/../image-name.sh" librarytest/jetty-hello-web "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/index.jsp /var/lib/jetty/webapps/ROOT/
EOD
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":jetty \
		"$clientImage" \
		curl -fs -X"$method" "$@" "http://jetty:8080/$url"
}

# Make sure that Jetty is listening on port 8080
. "$dir/../../retry.sh" --tries 40 --sleep 0.25 '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request /index.jsp with no params
[ "$(_request GET "/" | tail -1)" = "null" ]

# Check that our index.jsp echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(_request GET "/?hello=$hello" | tail -1)" = "$hello" ]
