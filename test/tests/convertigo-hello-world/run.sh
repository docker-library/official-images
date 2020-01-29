#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":convertigo \
		"$clientImage" \
		curl -s "$@" "http://convertigo:28080/$url"
}

# Make sure that Tomcat is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that we can request /
[ -n "$(_request '/')" ]

# Check that the example "Hello World" servlet works
helloWorld="$(_request '/convertigo/admin/services/engine.CheckAuthentication')"
[[ "$helloWorld" == *'TEST_PLATFORM'* ]]
