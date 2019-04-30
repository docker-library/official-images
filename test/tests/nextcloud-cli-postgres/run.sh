#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

postgresImage='postgres:11-alpine'
serverImage="$1"
dbPass="test-$RANDOM-password-$RANDOM-$$"
dbName="test-$RANDOM-db"
dbUsr="test-$RANDOM-db"

# Create an instance of the container-under-test
# Static username due https://github.com/nextcloud/docker/issues/345
postgresCid="$(docker run -d \
	-e POSTGRES_USER="oc_postgres" \
	-e POSTGRES_PASSWORD="$dbPass" \
	-e POSTGRES_DB="$dbName" \
	"$postgresImage")"
trap "docker rm -vf $postgresCid > /dev/null" EXIT
cid="$(docker run -d --link "$postgresCid":postgres \
	-e POSTGRES_HOST="postgres" \
	-e POSTGRES_USER="oc_postgres" \
	-e POSTGRES_PASSWORD="$dbPass" \
	-e POSTGRES_DB="$dbName" \
	-e NEXTCLOUD_ADMIN_USER="postgres" \
	-e NEXTCLOUD_ADMIN_PASSWORD="test-$RANDOM-password" \
	"$serverImage")"
trap "docker rm -vf $cid $postgresCid > /dev/null" EXIT

_occ() {
	docker exec -u www-data $cid php occ $1
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_occ app:list' > /dev/null

# Check if NextCloud is installed
_occ status | grep -iq "installed: true"
_occ check
