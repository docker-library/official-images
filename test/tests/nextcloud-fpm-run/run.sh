#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# since we have curl in the php image, we'll use that
clientImage="$1"
serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

# Build a client image with cgi-fcgi for testing
nginxImage="$("$dir/../image-name.sh" librarytest/nextcloud-fpm-run-nginx "$1")"
"$dir/../docker-build.sh" "$dir" "$nginxImage" <<EOD
FROM nginx:alpine
COPY dir/nginx-default.conf /etc/nginx/conf.d/default.conf
EOD

serverImage="$1"

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT
nginxCid="$(docker run -d --link "$cid":fpm --volumes-from "$cid" "$nginxImage")"
trap "docker rm -vf $nginxCid $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$nginxCid":nginx "$clientImage" \
		curl -fsL -X"$method" "$@" "http://nginx/$url"
}

# Make sure that PHP-FPM is listening and ready
. "$dir/../../retry.sh" --tries 30 '_request GET / --output /dev/null'

# Check that we can request / and that it contains the pattern "Finish setup" somewhere
# <input type="submit" class="primary" value="Finish setup" data-finishing="Finishing …">
_request GET '/' |tac|tac| grep -iq "Finish setup"
# (without "|tac|tac|" we get "broken pipe" since "grep" closes the pipe before "curl" is done reading it)
