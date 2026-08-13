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

_cli() {
	docker exec -u www-data "$cid" php installation/joomla.php install -n \
	--site-name="test-$RANDOM" \
	--admin-user="test-$RANDOM" \
	--admin-username="test-$RANDOM" \
	--admin-password="test-$RANDOM-password" \
	--admin-email="test@test.test" \
	--db-type="mysql" \
	--db-host="db" \
	--db-user="$dbUsr" \
	--db-pass="$dbPass" \
	--db-name="$dbName"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 20 --sleep 5 'docker exec "$cid" ls installation/joomla.php'

# Check if Joomla is installed
_cli
docker exec -u www-data "$cid" php cli/joomla.php list | grep -i 'Joomla!'
