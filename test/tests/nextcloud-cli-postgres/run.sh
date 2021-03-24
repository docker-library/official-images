#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

dbImage='postgres:11-alpine'
# ensure the dbImage is ready and available
if ! docker image inspect "$dbImage" &> /dev/null; then
	docker pull "$dbImage" > /dev/null
fi
serverImage="$1"
dbPass="test-$RANDOM-password-$RANDOM-$$"
dbName="test_${RANDOM}_db" # dbName has to be set to something that does not require escaping: https://github.com/docker-library/official-images/pull/6252#issuecomment-520095703
dbUsr="test-$RANDOM-db"

# Create an instance of the container-under-test
# not setting POSTGRES_DB due to https://github.com/nextcloud/docker/issues/345
dbCid="$(docker run -d \
	-e POSTGRES_USER="$dbUsr" \
	-e POSTGRES_PASSWORD="$dbPass" \
	-e POSTGRES_DB='postgres' \
	"$dbImage")"
trap "docker rm -vf $dbCid > /dev/null" EXIT
# NEXTCLOUD_ADMIN_USER has to be set to something that does not require escaping: https://github.com/docker-library/official-images/pull/6252#issuecomment-520095703
cid="$(docker run -d \
	--link "$dbCid":db \
	-e POSTGRES_HOST='db' \
	-e POSTGRES_USER="$dbUsr" \
	-e POSTGRES_PASSWORD="$dbPass" \
	-e POSTGRES_DB="$dbName" \
	-e NEXTCLOUD_ADMIN_USER="test_$RANDOM" \
	-e NEXTCLOUD_ADMIN_PASSWORD="test-$RANDOM-password" \
	"$serverImage")"
trap "docker rm -vf $cid $dbCid > /dev/null" EXIT

_occ() {
	docker exec -u www-data "$cid" php occ "$@"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 60 '_occ app:list' > /dev/null

# Check if NextCloud is installed
_occ status | grep -iq 'installed: true'
_occ check
