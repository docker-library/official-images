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
attempts=40
tried="$attempts"
duration=0.25
while [ "$tried" -ge 0 -a "$(_request GET / --output /dev/null || echo $?)" = 7 ]; do
	(( tried-- ))

	if [ "$tried" -le 0 ]; then
		echo >&2 "Unable to connect to Jetty. Aborting."
		exit 1
	fi

	echo >&2 -n .

	sleep "$duration"
done

# Check that we can request /index.jsp with no params
[ "$(_request GET "/" | tail -1)" = "null" ]

# Check that our index.jsp echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(_request GET "/?hello=$hello" | tail -1)" = "$hello" ]
