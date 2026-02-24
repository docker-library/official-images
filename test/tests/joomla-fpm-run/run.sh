#!/bin/bash
set -Eeo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

dbImage='mariadb:10.11'
# ensure the dbImage is ready and available
if ! docker image inspect "$dbImage" &> /dev/null; then
	docker pull "$dbImage" > /dev/null
fi
serverImage="$1"
dbPass="test-$RANDOM-password-$RANDOM-$$"
dbName="test-$RANDOM-db"
dbUsr="test-$RANDOM-db"

# Build a client image with cgi-fcgi for testing
clientImage='librarytest/joomla-fpm-run:fcgi-client'
docker build -t "$clientImage" - > /dev/null <<'EOF'
FROM debian:buster-slim

RUN set -x && apt-get update && apt-get install -y --no-install-recommends libfcgi-bin && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cgi-fcgi"]
EOF

# Create an instance of the container-under-test
dbCid="$(docker run -d \
	-e MYSQL_RANDOM_ROOT_PASSWORD=yes \
	-e MYSQL_USER="$dbUsr" \
	-e MYSQL_PASSWORD="$dbPass" \
	-e MYSQL_DATABASE="$dbName" \
	"$dbImage")"
trap "docker rm -vf $dbCid > /dev/null" EXIT
cid="$(docker run -d \
	--link "$dbCid":db \
	-e JOOMLA_DB_HOST="db:3306" \
	-e JOOMLA_DB_NAME="$dbName" \
	-e JOOMLA_DB_USER="$dbUsr" \
	-e JOOMLA_DB_PASSWORD="$dbPass" \
	"$serverImage")"
trap "docker rm -vf $cid $dbCid > /dev/null" EXIT

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
. "$dir/../../retry.sh" --tries 5 --sleep 10 'fcgi-request GET /index.php' > /dev/null 2>&1

# Check that we can request / and that it contains the pattern 'Joomla Installer' somewhere
fcgi-request GET '/installation/index.php' #| grep -qi 'Joomla Installer'
