#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

serverImage="$("$dir/../image-name.sh" librarytest/php-apache-hello-web "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/index.php /var/www/html/
EOD

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
		curl -fs -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening
. "$dir/../../retry.sh" '[ "$(_request GET / --output /dev/null || echo $?)" != 7 ]'

# Check that we can request /index.php with no params
[ -n "$(_request GET "/index.php")" ]

# Check that our index.php echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(_request GET "/index.php?hello=$hello" | tail -1)" = "$hello" ]
