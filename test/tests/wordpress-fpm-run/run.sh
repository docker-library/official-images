#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# since we have curl in the php image, we'll use that
clientImage="$1"

# Build a client image with cgi-fcgi for testing
nginxImage="$("$dir/../image-name.sh" librarytest/wordpress-fpm-run-nginx "$1")"
"$dir/../docker-build.sh" "$dir" "$nginxImage" <<EOD
FROM nginx:alpine
COPY dir/nginx-default.conf /etc/nginx/conf.d/default.conf
EOD

mysqlImage='mysql:5.7'
serverImage="$1"

# Create an instance of the container-under-test
mysqlCid="$(docker run -d -e MYSQL_ROOT_PASSWORD="test-$RANDOM-password-$RANDOM-$$" "$mysqlImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT
cid="$(docker run -d --link "$mysqlCid":mysql "$serverImage")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT
nginxCid="$(docker run -d --link "$cid":fpm --volumes-from "$cid" "$nginxImage")"
trap "docker rm -vf $nginxCid $cid $mysqlCid > /dev/null" EXIT

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
# (give it a bit long since it won't start until MySQL is started and ready)

# Check that we can request / and that it contains the word "setup" somewhere
# <form id="setup" method="post" action="?step=1"><label class='screen-reader-text' for='language'>Select a default language</label>
_request GET '/' |tac|tac| grep -iq setup
# (without "|tac|tac|" we get "broken pipe" since "grep" closes the pipe before "curl" is done reading it)
