#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":open-liberty \
		"$clientImage" \
		curl -fsSL "$@" "http://open-liberty:9080/$url"
}

# Make sure that Open Liberty is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that we can request /
[ -n "$(_request '/')" ]

# Check that the version.js file can be retrieved.
helloWorld="$(_request '/version.js')"
[[ "$helloWorld" == *'var current'* ]]
