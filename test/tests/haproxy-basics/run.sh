#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

clientImage='buildpack-deps:bookworm-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi
_curl() {
	local container="$1"; shift
	local url="$1"; shift
	docker run --rm --interactive \
		--link "$container":container \
		"$clientImage" \
		curl \
		-fsSL \
		--connect-to '::container:' \
		"http://container/${url%/}"
}

httpdImage='busybox'
# ensure the httpdImage is ready and available
if ! docker image inspect "$httpdImage" &> /dev/null; then
	docker pull "$httpdImage" > /dev/null
fi
httpdText="hello from httpd $RANDOM $RANDOM $RANDOM"
httpd="$(docker run -d --rm --init "$httpdImage" sh -euxc 'echo "$@" > index.html && exec httpd -f' -- "$httpdText")"
trap "docker rm -vf $httpd > /dev/null" EXIT

testHttpd="$(_curl "$httpd" '/')"
[ "$testHttpd" = "$httpdText" ]

# Create an instance of the container-under-test
serverImage="$("$dir/../image-name.sh" librarytest/haproxy-basics "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/haproxy.cfg /usr/local/etc/haproxy/
EOD
cid="$(docker run -d --link "$httpd":httpd "$serverImage")"
trap "docker rm -vf $cid $httpd > /dev/null" EXIT

#. "$dir/../../retry.sh" '_curl "$cid" / &> /dev/null'

haproxy="$(_curl "$cid" '/')"
[ "$haproxy" = "$httpdText" ]
