#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

export MYSQL_ROOT_PASSWORD='this is an example test password'
export MYSQL_USER='0123456789012345' # "ERROR: 1470  String 'my cool mysql user' is too long for user name (should be no longer than 16)"
export MYSQL_PASSWORD='my cool mysql password'
export MYSQL_DATABASE='my cool mysql database'
VERSION=$(docker run --rm "$image" --version | awk '{print$3}')

if [[ $VERSION =~ ^5.[56] ]]; then
	echo [skipped] no RocksDB support in 5.5, 5.6
	exit 0
fi

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e INIT_ROCKSDB=1 \
		-e MYSQL_ROOT_PASSWORD \
		-e MYSQL_USER \
		-e MYSQL_PASSWORD \
		-e MYSQL_DATABASE \
		--name "$cname" \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

mysql() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint mysql \
		-e MYSQL_PWD="$MYSQL_PASSWORD" \
		"$image" \
		-hmysql \
		-u"$MYSQL_USER" \
		--silent \
		"$@" \
		"$MYSQL_DATABASE"
}

. "$dir/../../retry.sh" --tries 20 "echo 'SELECT 1' | mysql"

echo 'CREATE TABLE test (a INT, b INT, c VARCHAR(255)) ENGINE=RocksDB' | mysql
[ "$(echo 'SELECT COUNT(*) FROM test' | mysql)" = 0 ]
