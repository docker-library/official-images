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

# The keygen below is a bit ugly, because spiped-generate-key.sh expects /spiped/key to be a directory (you can't bind mount a non-existing file),
# but the entrypoint expects /spiped/key to be the actual keyfile.
# So we first symlink /spiped/key to some directory, then generate the keyfile and then replace the symlink by the generated keyfile.
cid_keygen="$(docker run -d "$image" sh -c 'ln -s /tmp /spiped/key && spiped-generate-key.sh && rm /spiped/key && mv /tmp/spiped-keyfile /spiped/key')"
trap "docker rm -vf $cid_keygen > /dev/null" EXIT
cid_d="$(docker run --volumes-from="$cid_keygen" -d "$image" -d -s '[0.0.0.0]:8080' -t 'example.com:80')"
trap "docker rm -vf $cid_keygen $cid_d > /dev/null" EXIT
cid_e="$(docker run --volumes-from="$cid_keygen" --link "$cid_d":spiped_d -d "$image" -e -s '[0.0.0.0]:80' -t 'spiped_d:8080')"
trap "docker rm -vf $cid_keygen $cid_d $cid_e > /dev/null" EXIT

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
_request GET http '/' | grep '<h1>Example Domain</h1>' > /dev/null
