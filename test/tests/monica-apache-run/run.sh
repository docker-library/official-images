#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

dbImage='mysql:8.0'
# ensure the dbImage is ready and available
if ! docker image inspect "$dbImage" &> /dev/null; then
	docker pull "$dbImage" > /dev/null
fi

# Create an instance of the container-under-test
mysqlCid="$(docker run -d \
	-e MYSQL_RANDOM_ROOT_PASSWORD=true \
	-e MYSQL_DATABASE=monica \
	-e MYSQL_USER=homestead \
	-e MYSQL_PASSWORD=secret \
	"$dbImage")"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT

cid="$(docker run -d \
	--link "$mysqlCid":mysql \
	-e DB_HOST=mysql \
	"$image")"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm --link "$cid":apache "$image" \
		curl -fsL -X"$method" "$@" "http://apache/$url"
}

# Make sure that Apache is listening and ready
. "$dir/../../retry.sh" --tries 30 '_request GET / --output /dev/null'

# Check that we can request / and that it contains the pattern "Welcome" somewhere
_request GET '/' | grep -i "Welcome" > /dev/null
