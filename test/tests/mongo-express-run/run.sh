#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

clientImage='buildpack-deps:buster-curl'

mongoImage='mongo:4.0'
serverImage="$1"

# Create an instance of the container-under-test
mongoCid="$(docker run -d "$mongoImage")"
trap "docker rm -vf $mongoCid > /dev/null" EXIT
cid="$(docker run -d --link "$mongoCid":mongo "$serverImage")"
trap "docker rm -vf $cid $mongoCid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":me "$clientImage" \
		curl -fsL -X"$method" "$@" "http://me:8081/$url"
}

# make sure that mongo-express is listening and ready
. "$dir/../../retry.sh" '_request GET / --output /dev/null'

# if we evetually got a "200 OK" response from mongo-express, it should be ~working fine!
# (since it fails to even start if it can't connect to MongoDB, etc)
