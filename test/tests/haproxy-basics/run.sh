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
serverImage="$("$dir/../image-name.sh" librarytest/haproxy-basics "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/haproxy.cfg /usr/local/etc/haproxy/
EOD
cid="$(docker run -d --sysctl net.ipv4.ip_unprivileged_port_start=0 "$serverImage")"
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
_request GET http '/' | grep '<h1>Example Domain</h1>' > /dev/null
_request GET https '/' | grep '<h1>Example Domain</h1>' > /dev/null
