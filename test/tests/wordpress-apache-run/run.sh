#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

mysqlImage='mysql:5.7'
# ensure the mysqlImage is ready and available
if ! docker image inspect "$mysqlImage" &> /dev/null; then
	docker pull "$mysqlImage" > /dev/null
fi
serverImage="$1"

# Create an instance of the container-under-test
mysqlCid="$(docker run -d -e MYSQL_ROOT_PASSWORD="test-$RANDOM-password-$RANDOM-$$" "$mysqlImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT
cid="$(docker run -d --link "$mysqlCid":mysql "$serverImage")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":apache \
		"$clientImage" \
		curl -fsL -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening and ready
. "$dir/../../retry.sh" --tries 30 '_request GET / --output /dev/null'
# (give it a bit long since it won't start until MySQL is started and ready)

# Check that we can request / and that it contains the word "setup" somewhere
# <form id="setup" method="post" action="?step=1"><label class='screen-reader-text' for='language'>Select a default language</label>
_request GET '/' | grep -i setup > /dev/null
