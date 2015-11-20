#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image since it should already have curl
clientImage="$image"

# Create an instance of the container-under-test
cid="$(docker run -d "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":es "$clientImage" \
		curl -fs -X"$method" "$@" "http://es:9200/$url"
}

_trimmed() {
	_request "$@" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g'
}

# Make sure our container is listening
. "$dir/../../retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Perform simple health check
[ "$(_trimmed GET '/_cat/health?h=status')" = 'green' ]
# should be green because it's empty and fresh

[ "$(_trimmed GET '/_cat/indices/test1?h=docs.count')" = '' ]
[ "$(_trimmed GET '/_cat/indices/test2?h=docs.count')" = '' ]

doc='{"a":"b","c":{"d":"e"}}'
_request POST '/test1/test/1' --data "$doc" -o /dev/null
[ "$(_trimmed GET '/_cat/indices/test1?h=docs.count')" = 1 ]
[ "$(_trimmed GET '/_cat/indices/test2?h=docs.count')" = '' ]

_request POST '/test2/test/1' --data "$doc" -o /dev/null
[ "$(_trimmed GET '/_cat/indices/test1?h=docs.count')" = 1 ]
[ "$(_trimmed GET '/_cat/indices/test2?h=docs.count')" = 1 ]

[ "$(_trimmed GET '/test1/test/1/_source')" = "$doc" ]
[ "$(_trimmed GET '/test2/test/1/_source')" = "$doc" ]

_request DELETE '/test1/test/1' -o /dev/null
[ "$(_trimmed GET '/_cat/indices/test1?h=docs.count')" = 0 ]
[ "$(_trimmed GET '/_cat/indices/test2?h=docs.count')" = 1 ]

_request DELETE '/test2/test/1' -o /dev/null
[ "$(_trimmed GET '/_cat/indices/test1?h=docs.count')" = 0 ]
[ "$(_trimmed GET '/_cat/indices/test2?h=docs.count')" = 0 ]
