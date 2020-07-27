#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# Create an instance of the container-under-test
serverImage="$("$dir/../image-name.sh" librarytest/spiped "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/keyfile /spiped/key
EOD
cid_d="$(docker run -d "$serverImage" -d -s '[0.0.0.0]:8080' -t 'example.com:80')"
cid_e="$(docker run --link "$cid_d":spiped_d -d "$serverImage" -e -s '[0.0.0.0]:80' -t 'spiped_d:8080')"
trap "docker rm -vf $cid_d > /dev/null" EXIT
trap "docker rm -vf $cid_e > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local proto="$1"
	shift

	local url="${1#/}"
	shift

	if [ "$(docker inspect -f '{{.State.Running}}' "$cid_d" 2>/dev/null)" != 'true' ]; then
		echo >&2 "$image stopped unexpectedly!"
		( set -x && docker logs "$cid_d" ) >&2 || true
		false
	fi
	
	if [ "$(docker inspect -f '{{.State.Running}}' "$cid_e" 2>/dev/null)" != 'true' ]; then
		echo >&2 "$image stopped unexpectedly!"
		( set -x && docker logs "$cid_e" ) >&2 || true
		false
	fi

	docker run --rm \
		--link "$cid_e":spiped \
		"$clientImage" \
		curl -fsSL -X"$method" --connect-to '::spiped:' "$@" "$proto://example.com/$url"
}

. "$dir/../../retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request / (which is proxying example.com)
_request GET http '/' |tac|tac| grep -q '<h1>Example Domain</h1>'
