#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# since we have curl in the convertigo image, we'll use that
clientImage="$1"

serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm --link "$cid":convertigo "$clientImage" \
		curl -s "$@" "http://convertigo:28080/$url"
}

# Make sure that Tomcat is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that we can request /
[ -n "$(_request '/')" ]

# Check that the example "Hello World" servlet works
helloWorld="$(_request '/convertigo/admin/services/engine.CheckAuthentication')"
[[ "$helloWorld" == *'TEST_PLATFORM'* ]]
