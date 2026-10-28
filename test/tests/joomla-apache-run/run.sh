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

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

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

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":apache \
		"$clientImage" \
		curl -fsL -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening and ready
. "$dir/../../retry.sh" --tries 5 --sleep 10 '_request GET / --output /dev/null'

# Check that we can request / and that it contains the pattern 'Joomla Installer' somewhere
_request GET '/' | grep -i 'Joomla Installer'
