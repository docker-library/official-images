#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/php-fpm-hello-web:fcgi-client'
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:buster-slim

RUN set -x && apt-get update && apt-get install -y --no-install-recommends libfcgi-bin && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

serverImage="$("$dir/../image-name.sh" librarytest/php-fpm-hello-web "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/index.php /var/www/html/
EOD

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

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

# wait until ready
. "$dir/../../retry.sh" --tries 30 'fcgi-request GET /index.php' > /dev/null 2>&1

# Check that we can request /index.php with no params
[ -n "$(fcgi-request GET "/index.php")" ]

# Check that our index.php echoes the value of the "hello" param
hello="world-$RANDOM-$RANDOM"
[ "$(fcgi-request GET "/index.php?hello=$hello" | tail -1)" = "$hello" ]
