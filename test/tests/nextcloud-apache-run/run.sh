#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# since we have curl in the php image, we'll use that
clientImage="$1"
serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":apache "$clientImage" \
		curl -fsL -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening and ready
. "$dir/../../retry.sh" --tries 30 '_request GET / --output /dev/null'

# Check that we can request / and that it contains the pattern "Finish setup" somewhere
# <input type="submit" class="primary" value="Finish setup" data-finishing="Finishing …">
_request GET '/' |tac|tac| grep -iq "Finish setup"
# (without "|tac|tac|" we get "broken pipe" since "grep" closes the pipe before "curl" is done reading it)
