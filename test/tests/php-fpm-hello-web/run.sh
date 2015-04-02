#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/php-fpm-hello-web:fcgi'
docker build -q -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:jessie

RUN set -x; apt-get update && apt-get install -y libfcgi0ldbl && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

# Create an instance of the container-under-test
cname="php-fpm-container-$RANDOM-$RANDOM"
cid="$(docker run -d -v "$dir/index.php":/var/www/html/index.php:ro --name "$cname" "$image")"
trap "docker rm -f $cid > /dev/null" EXIT

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
		"$clientImage" \
		-bind -connect fpm:9000
}

# Check that we can request /index.php with no params
[ -n "$(fcgi-request GET "/index.php")" ]

# Check that our index.php echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(fcgi-request GET "/index.php?hello=$hello" | tail -1)" = "$hello" ]
