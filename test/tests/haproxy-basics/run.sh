#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

clientImage='buildpack-deps:buster-curl'

# Create an instance of the container-under-test
serverImage="$("$dir/../image-name.sh" librarytest/haproxy-basics "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/haproxy.cfg /usr/local/etc/haproxy/
EOD
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local proto="$1"
	shift

	local url="${1#/}"
	shift

	if [ "$(docker inspect -f '{{.State.Running}}' "$cid" 2>/dev/null)" != 'true' ]; then
		echo >&2 "$image stopped unexpectedly!"
		( set -x && docker logs "$cid" ) >&2 || true
		false
	fi

	docker run --rm \
		--link "$cid":haproxy \
		"$clientImage" \
		curl -fsSL -X"$method" --connect-to '::haproxy:' "$@" "$proto://example.com/$url"
}

. "$dir/../../retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request / (which is proxying example.com)
_request GET http '/' |tac|tac| grep -q '<h1>Example Domain</h1>'
_request GET https '/' |tac|tac| grep -q '<h1>Example Domain</h1>'
