#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/nextcloud-fpm-run:fcgi-client'
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:stretch-slim

RUN set -x && apt-get update && apt-get install -y libfcgi0ldbl && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

# Create an instance of the container-under-test
cid="$(docker run -d "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

fcgi-request() {
	local method="$1"

	local url="$2"
	local queryString=
	if [[ "$url" == *\?* ]]; then
		queryString="${url#*\?}"
		url="${url%%\?*}"
	fi

	docker run --rm -i \
		--link "$cid":fpm \
		-e REQUEST_METHOD="$method" \
		-e SCRIPT_NAME="$url" \
		-e SCRIPT_FILENAME=/var/www/html/"${url#/}" \
		-e QUERY_STRING="$queryString" \
		"$clientImage" \
		-bind -connect fpm:9000
}

# Make sure that PHP-FPM is listening and ready
. "$dir/../../retry.sh" --tries 30 'fcgi-request GET /index.php' > /dev/null 2>&1

# Check that we can request / and that it contains the pattern "Finish setup" somewhere
# <input type="submit" class="primary" value="Finish setup" data-finishing="Finishing …">
fcgi-request GET '/index.php' |tac|tac| grep -iq "Finish setup"
# (without "|tac|tac|" we get "broken pipe" since "grep" closes the pipe before "curl" is done reading it)
