#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage="librarytest/monica-fpm-run:fcgi-client"
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:stretch-slim

RUN set -x && apt-get update && apt-get install -y libfcgi0ldbl && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

dbImage='mysql:8.0'
# ensure the dbImage is ready and available
if ! docker image inspect "$dbImage" &> /dev/null; then
	docker pull "$dbImage" > /dev/null
fi

# Create an instance of the container-under-test
mysqlCid="$(docker run -d \
	-e MYSQL_RANDOM_ROOT_PASSWORD=true \
	-e MYSQL_DATABASE=monica \
	-e MYSQL_USER=homestead \
	-e MYSQL_PASSWORD=secret \
	"$dbImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT

cid="$(docker run -d \
	--link "$mysqlCid":mysql \
	-e DB_HOST=mysql \
	"$image")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

fcgi-request() {
	local method="$1"

	local url="$2"
	local requestUri="$3"
	local queryString=
	if [[ "$url" == *\?* ]]; then
		queryString="${url#*\?}"
		url="${url%%\?*}"
	fi

	docker run --rm -i --link "$cid":fpm \
		-e REQUEST_METHOD="$method" \
		-e SCRIPT_NAME="$url" \
		-e SCRIPT_FILENAME=/var/www/html/public/"${url#/}" \
		-e QUERY_STRING="$queryString" \
		-e REQUEST_URI="$requestUri" \
		"$clientImage" \
		-bind -connect fpm:9000
}

# Make sure that PHP-FPM is listening and ready
. "$dir/../../retry.sh" --tries 30 'fcgi-request GET /index.php' > /dev/null 2>&1

# Check that we can request /register and that it contains the pattern "Welcome" somewhere
fcgi-request GET '/index.php' register | grep -i "Welcome" > /dev/null
