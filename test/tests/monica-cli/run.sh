#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

mysqlImage='mysql:5.7'
# ensure the mysqlImage is ready and available
if ! docker image inspect "$mysqlImage" &> /dev/null; then
	docker pull "$mysqlImage" > /dev/null
fi

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

_logs() {
	docker logs "$cid"
}

_artisan() {
	docker exec "$cid" php artisan "$@"
}

_artisan_test() {
	match=$1
	shift
	output=$(_artisan "$@")
	echo $output | grep -iq "$match" || echo "'$match' not found in: $output"
}

# Give some time to install
. "$dir/../../retry.sh" --tries 30 '_logs | grep -iq "Monica v.* is set up, enjoy."'

# Check if installation is complete
_artisan monica:getversion > /dev/null
_artisan_test 'Running scheduled command:' schedule:run
_artisan_test 'No scheduled commands are ready to run.' schedule:run
