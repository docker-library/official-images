#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/wordpress-fpm-run:fcgi-client'
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:buster-slim

RUN set -x && apt-get update && apt-get install -y --no-install-recommends libfcgi-bin && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

mysqlImage='mysql:5.7'
# ensure the mysqlImage is ready and available
if ! docker image inspect "$mysqlImage" &> /dev/null; then
	docker pull "$mysqlImage" > /dev/null
fi

# Create an instance of the container-under-test
mysqlCid="$(docker run -d -e MYSQL_ROOT_PASSWORD="test-$RANDOM-password-$RANDOM-$$" "$mysqlImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT
cid="$(docker run -d --link "$mysqlCid":mysql "$image")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

fcgi-request() {
	local method="$1"

	local url="$2"
	local queryString=
	if [[ "$url" == *\?* ]]; then
		queryString="${url#*\?}"
		url="${url%%\?*}"
	fi

	docker run --rm -i --link "$cid":fpm \
		-e REQUEST_METHOD="$method" \
		-e SCRIPT_NAME="$url" \
		-e SCRIPT_FILENAME=/var/www/html/"${url#/}" \
		-e QUERY_STRING="$queryString" \
		-e HTTP_HOST='localhost' \
		"$clientImage" \
		-bind -connect fpm:9000
}

# Make sure that PHP-FPM is listening and ready
. "$dir/../../retry.sh" --tries 30 'fcgi-request GET /index.php' > /dev/null 2>&1
# (give it a bit long since it won't start until MySQL is started and ready)

# index.php redirects to wp-admin/install.php, check that it contains the word "setup" somewhere
# <form id="setup" method="post" action="?step=1"><label class='screen-reader-text' for='language'>Select a default language</label>
fcgi-request GET '/wp-admin/install.php' | grep -i setup > /dev/null
