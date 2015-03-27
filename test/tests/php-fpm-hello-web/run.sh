#!/bin/bash

set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
client_image="php-fpm-client-$RANDOM-$RANDOM"
docker build -q -t "$client_image" - > /dev/null <<EOF
FROM debian:jessie

RUN set -x; apt-get update && apt-get install -y libfcgi0ldbl && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

# Create an instance of the container-under-test
cname="php-fpm-container-$RANDOM-$RANDOM"
cid="$(docker run -d -v "$dir/index.php":/var/www/html/index.php:ro --name "$cname" "$image")"
trap "docker rm -f $cid > /dev/null" EXIT

cgi-fcgi() {
	docker run --rm -i --link "$cname":fpm \
		-e REQUEST_METHOD=GET \
		-e SCRIPT_NAME=/index.php \
		-e SCRIPT_FILENAME=/var/www/html/index.php \
		-e QUERY_STRING="$1" \
		"$client_image" \
		-bind -connect fpm:9000
}

# Check that our index.php echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(cgi-fcgi hello="$hello" | tail -1)" = "$hello" ]
