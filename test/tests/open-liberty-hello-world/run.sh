#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# since we have curl in the liberty image, we'll use that
clientImage="$1"

serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm --link "$cid":open-liberty "$clientImage" \
		wget -q -O - "$@" "http://open-liberty:9080/$url"
}

# Make sure that Open Liberty is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that we can request /
[ -n "$(_request '/')" ]

# Check that the version.js file can be retrieved.
helloWorld="$(_request '/version.js')"
[[ "$helloWorld" == *'var current'* ]]
