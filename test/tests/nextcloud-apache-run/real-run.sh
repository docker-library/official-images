#!/bin/bash
set -Eeo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT
#trap "docker logs $cid" ERR

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

# Check that we can request / and that it contains the pattern "Install" somewhere
# <input type="submit" class="primary" value="Install" data-finishing="Installing …">
_request GET '/' | grep -i '"Install"' > /dev/null
# (https://github.com/nextcloud/server/blob/68b2463107774bed28ee9e77b44e7395d49dacee/core/templates/installation.php#L164)
