#!/bin/bash
set -Eeo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/nextcloud-fpm-run:fcgi-client'
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:buster-slim

RUN set -x && apt-get update && apt-get install -y --no-install-recommends libfcgi-bin && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

# Create an instance of the container-under-test
cid="$(docker run -d "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT
#trap "docker logs $cid" ERR

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

# Check that we can request / and that it contains the pattern "Install" somewhere
# <input type="submit" class="primary" value="Install" data-finishing="Installing …">
fcgi-request GET '/index.php' | grep -i '"Install"' > /dev/null
# (https://github.com/nextcloud/server/blob/68b2463107774bed28ee9e77b44e7395d49dacee/core/templates/installation.php#L164)
