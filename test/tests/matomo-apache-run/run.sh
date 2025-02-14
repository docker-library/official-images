#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Use a client image with curl for testing
clientImage='buildpack-deps:bookworm-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi
serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":apache \
		"$clientImage" \
		curl -fsL -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening and ready
. "$dir/../../retry.sh" --tries 10 '_request GET / --output /dev/null'

# Check that we can request / and that it contains the word "installation" somewhere
_request GET '/' | grep -i installation > /dev/null
