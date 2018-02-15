#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# since the "slim" tomcat variants don't have wget, we'll use buildpack-deps
clientImage='buildpack-deps:stretch-curl'

serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm --link "$cid":tomcat "$clientImage" \
		wget -q -O - "$@" "http://tomcat:8080/$url"
}

# Make sure that Tomcat is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that we can request /
[ -n "$(_request '/')" ]

# Check that the example "Hello World" servlet works
helloWorld="$(_request '/examples/servlets/servlet/HelloWorldExample')"
[[ "$helloWorld" == *'Hello World!'* ]]
