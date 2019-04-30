#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

mysqlImage='mariadb:10'
serverImage="$1"
dbPass="test-$RANDOM-password-$RANDOM-$$"
dbName="test-$RANDOM-db"
dbUsr="test-$RANDOM-db"

# Create an instance of the container-under-test
mysqlCid="$(docker run -d \
	-e MYSQL_RANDOM_ROOT_PASSWORD=yes \
	-e MYSQL_USER="$dbUsr" \
	-e MYSQL_PASSWORD="$dbPass" \
	-e MYSQL_DATABASE="$dbName" \
	"$mysqlImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT
cid="$(docker run -d --link "$mysqlCid":mysql \
	-e MYSQL_HOST="mysql" \
	-e MYSQL_USER="$dbUsr" \
	-e MYSQL_PASSWORD="$dbPass" \
	-e MYSQL_DATABASE="$dbName" \
	-e NEXTCLOUD_ADMIN_USER="test-$RANDOM-user" \
	-e NEXTCLOUD_ADMIN_PASSWORD="test-$RANDOM-password" \
	"$serverImage")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

_occ() {
	docker exec -u www-data $cid php occ $1
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_occ app:list' > /dev/null

# Check if NextCloud is installed
_occ status | grep -iq "installed: true"
_occ check
