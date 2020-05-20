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
# (explicitly setting a low memory limit since the image defaults to 2GB)
# (disable "bootstrap checks" by setting discovery.type option)
cid="$(docker run -d -e ES_JAVA_OPTS='-Xms128m -Xmx128m' -e discovery.type=single-node "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	# https://github.com/docker/docker/issues/14203#issuecomment-129865960 (DOCKER_FIX)
	docker run --rm --link "$cid":es \
		-e DOCKER_FIX='                                        ' \
		"$clientImage" \
		curl -fs -X"$method" "$@" "http://es:9200/$url"
}

_trimmed() {
	_request "$@" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g'
}

_req-comp() {
	local method="$1"; shift
	local url="$1"; shift
	local expected="$1"; shift
	response="$(_trimmed "$method" "$url")"
	[ "$response" = "$expected" ]
}

_req-exit() {
	local method="$1"; shift
	local url="$1"; shift
	local expectedRet="$1"; shift
	[ "$(_request "$method" "$url" --output /dev/null || echo "$?")" = "$expectedRet" ]
}

# Make sure our container is listening
. "$dir/../../retry.sh" '! _req-exit GET / 7' # "Failed to connect to host."

# Perform simple health check
_req-comp GET '/_cat/health?h=status' 'green'
# should be green because it's empty and fresh

_req-exit GET '/_cat/indices/test1?h=docs.count' 22 # "HTTP page not retrieved. 4xx"
_req-exit GET '/_cat/indices/test2?h=docs.count' 22 # "HTTP page not retrieved. 4xx"

doc='{"a":"b","c":{"d":"e"}}'
_request POST '/test1/test/1?refresh=true' --data "$doc" --header 'Content-Type: application/json' -o /dev/null
_req-comp GET '/_cat/indices/test1?h=docs.count' 1
_req-exit GET '/_cat/indices/test2?h=docs.count' 22 # "HTTP page not retrieved. 4xx"

_request POST '/test2/test/1?refresh=true' --data "$doc" --header 'Content-Type: application/json' -o /dev/null
_req-comp GET '/_cat/indices/test1?h=docs.count' 1
_req-comp GET '/_cat/indices/test2?h=docs.count' 1

_req-comp GET '/test1/test/1/_source' "$doc"
_req-comp GET '/test2/test/1/_source' "$doc"

_request DELETE '/test1/test/1?refresh=true' -o /dev/null
_req-comp GET '/_cat/indices/test1?h=docs.count' 0
_req-comp GET '/_cat/indices/test2?h=docs.count' 1

_request DELETE '/test2/test/1?refresh=true' -o /dev/null
_req-comp GET '/_cat/indices/test1?h=docs.count' 0
_req-comp GET '/_cat/indices/test2?h=docs.count' 0
