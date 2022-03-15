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
serverImage="$("$dir/../image-name.sh" librarytest/rapidoid-hello-web "$image")"

"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
RUN mkdir -p /app/static
COPY dir/index.html /app/static/
EOD

cid="$(docker run -d "$serverImage" app.services=ping)"

trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":rapidoid \
		"$clientImage" \
		curl -fs -X"$method" "$@" "http://rapidoid:8888/$url"
}

# Make sure that Rapidoid is listening on port 8888
. "$dir/../../retry.sh" --tries 40 --sleep 0.25 '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Make sure that Rapidoid serves the static page index.html
[ "$(_request GET "/")" = "Hello world!" ]
[ "$(_request GET "/index.html")" = "Hello world!" ]

# Make sure that Rapidoid's built-in Ping service works correctly
[ "$(_request GET "/rapidoid/ping")" = "OK" ]
