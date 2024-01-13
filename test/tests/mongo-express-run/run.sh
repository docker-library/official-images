#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"

clientImage='buildpack-deps:bookworm-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

mongoImage='mongo:4.0'
# ensure the mongoImage is ready and available
if ! docker image inspect "$mongoImage" &> /dev/null; then
	docker pull "$mongoImage" > /dev/null
fi

# Create an instance of the container-under-test
mongoCid="$(docker run -d "$mongoImage")"
trap "docker rm -vf $mongoCid > /dev/null" EXIT
cid="$(docker run \
	--detach \
	--link "$mongoCid":mongo \
	--env ME_CONFIG_BASICAUTH_USERNAME="test-user" \
	--env ME_CONFIG_BASICAUTH_PASSWORD="test-password" \
	"$serverImage"
)"
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
. "$dir/../../retry.sh" '_request GET / --output /dev/null --user test-user:test-password'

# if we evetually got a "200 OK" response from mongo-express, it should be ~working fine!
# (since it fails to even start if it can't connect to MongoDB, etc)
