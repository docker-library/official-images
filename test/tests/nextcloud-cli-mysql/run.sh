#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

dbImage='mariadb:10.5'
# ensure the dbImage is ready and available
if ! docker image inspect "$dbImage" &> /dev/null; then
	docker pull "$dbImage" > /dev/null
fi
serverImage="$1"
dbPass="test-$RANDOM-password-$RANDOM-$$"
dbName="test-$RANDOM-db"
dbUsr="test-$RANDOM-db"

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
	-e MYSQL_HOST="db" \
	-e MYSQL_USER="$dbUsr" \
	-e MYSQL_PASSWORD="$dbPass" \
	-e MYSQL_DATABASE="$dbName" \
	-e NEXTCLOUD_ADMIN_USER="test-$RANDOM-user" \
	-e NEXTCLOUD_ADMIN_PASSWORD="test-$RANDOM-password" \
	"$serverImage")"
trap "docker rm -vf $cid $dbCid > /dev/null" EXIT

_occ() {
	docker exec -u www-data "$cid" php occ "$@"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_occ app:list' > /dev/null

# Check if NextCloud is installed
_occ status | grep -iq 'installed: true'
_occ check
