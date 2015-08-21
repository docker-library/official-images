#!/bin/bash
set -e

image="$1"
testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

export MYSQL_ROOT_PASSWORD='this is an example test password'
export MYSQL_USER='0123456789012345' # "ERROR: 1470  String 'my cool mysql user' is too long for user name (should be no longer than 16)"
export MYSQL_PASSWORD='my cool mysql password'
export MYSQL_DATABASE='my cool mysql database'

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ROOT_PASSWORD \
		-e MYSQL_USER \
		-e MYSQL_PASSWORD \
		-e MYSQL_DATABASE \
		--name "$cname" \
		-v "$testDir/initdb.sql:/docker-entrypoint-initdb.d/test.sql":ro \
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

tries=20
while ! echo 'SELECT 1' | mysql &> /dev/null; do
	(( tries-- ))
	if [ $tries -le 0 ]; then
		echo >&2 'mysqld failed to accept connections in a reasonable amount of time!'
		( set -x && docker logs "$cid" ) >&2 || true
		echo 'SELECT 1' | mysql # to hopefully get a useful error message
		false
	fi
	sleep 2
done

[ "$(echo 'SELECT COUNT(*) FROM test' | mysql)" = 1 ]
[ "$(echo 'SELECT c FROM test' | mysql)" = 'goodbye!' ]
