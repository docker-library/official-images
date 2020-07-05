#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

mysqlImage='mysql:5.7'

# Create an instance of the container-under-test
mysqlCid="$(docker run -d \
	-e MYSQL_RANDOM_ROOT_PASSWORD=true \
	-e MYSQL_DATABASE=monica \
	-e MYSQL_USER=homestead \
	-e MYSQL_PASSWORD=secret \
	"$mysqlImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT

cid="$(docker run -d \
	--link "$mysqlCid":mysql \
	-e DB_HOST=mysql \
	"$image")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

_artisan() {
	docker exec "$cid" php artisan "$@"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_artisan migrate:status' > /dev/null

# Check if installation is complete
_artisan monica:getversion
_artisan schedule:run | grep -iq 'No scheduled commands are ready to run.'
