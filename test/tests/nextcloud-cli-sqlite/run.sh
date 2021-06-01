#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"
dbName="test-$RANDOM-db"

# Create an instance of the container-under-test
cid="$(docker run -d \
	-e SQLITE_DATABASE="$dbName" \
	-e NEXTCLOUD_ADMIN_USER="test-$RANDOM-user" \
	-e NEXTCLOUD_ADMIN_PASSWORD="test-$RANDOM-password" \
	"$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_occ() {
	docker exec -u www-data "$cid" php occ "$@"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_occ app:list' > /dev/null

# Check if NextCloud is installed
_occ status | grep -iq 'installed: true'
_occ check
