#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:bookworm-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

mysqlImage='mysql:8.0'
# ensure the mysqlImage is ready and available
if ! docker image inspect "$mysqlImage" &> /dev/null; then
	docker pull "$mysqlImage" > /dev/null
fi
mysqlUser="user-$RANDOM"
mysqlPassword="password-$RANDOM"
mysqlDatabase="database-$RANDOM"

# Create an instance of the container-under-test
mysqlCid="$(
	docker run -d \
		-e MYSQL_RANDOM_ROOT_PASSWORD=1 \
		-e MYSQL_USER="$mysqlUser" \
		-e MYSQL_PASSWORD="$mysqlPassword" \
		-e MYSQL_DATABASE="$mysqlDatabase" \
		"$mysqlImage"
)"
trap "docker rm -vf $mysqlCid > /dev/null" EXIT

# "Unknown database error" / "ECONNREFUSED" (and Ghost just crashing hard)
. "$dir/../../retry.sh" --tries 30 'docker exec -i -e MYSQL_PWD="$mysqlPassword" "$mysqlCid" mysql -h127.0.0.1 -u"$mysqlUser" --silent "$mysqlDatabase" <<<"SELECT 1"'

cid="$(
	docker run -d \
		--link "$mysqlCid":dbhost \
		-e database__client=mysql \
		-e database__connection__host=dbhost \
		-e database__connection__user="$mysqlUser" \
		-e database__connection__password="$mysqlPassword" \
		-e database__connection__database="$mysqlDatabase" \
		"$serverImage"
)"
trap "docker rm -vf $cid $mysqlCid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1}"
	shift

	docker run --rm \
		--link "$cid":ghost \
		"$clientImage" \
		curl -fs --max-time 15 -X"$method" "$@" "http://ghost:2368/${url#/}"
}

# Make sure that Ghost is listening and ready
. "$dir/../../retry.sh" '_request GET / --output /dev/null'

# Check that /ghost/ redirects to setup (the image is unconfigured by default)
ghostVersion="$(docker inspect --format '{{range .Config.Env}}{{ . }}{{"\n"}}{{end}}' "$serverImage" | awk -F= '$1 == "GHOST_VERSION" { print $2 }')"
case "$ghostVersion" in
	4.*) _request GET '/ghost/api/v4/admin/authentication/setup/' | grep 'status":false' > /dev/null ;;
	*) _request GET '/ghost/api/admin/authentication/setup/' | grep 'status":false' > /dev/null ;;
esac
