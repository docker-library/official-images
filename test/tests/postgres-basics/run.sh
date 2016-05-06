#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

export POSTGRES_USER='my cool postgres user'
export POSTGRES_PASSWORD='my cool postgres password'
export POSTGRES_DB='my cool postgres database'

cname="postgres-container-$RANDOM-$RANDOM"
cid="$(docker run -d -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_DB --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

psql() {
	docker run --rm -i \
		--link "$cname":postgres \
		--entrypoint psql \
		-e PGPASSWORD="$POSTGRES_PASSWORD" \
		"$image" \
		--host postgres \
		--username "$POSTGRES_USER" \
		--dbname "$POSTGRES_DB" \
		--quiet --no-align --tuples-only \
		"$@"
}

. "$dir/../../retry.sh" --tries "$POSTGRES_TEST_TRIES" --sleep "$POSTGRES_TEST_SLEEP" "echo 'SELECT 1' | psql"

echo 'CREATE TABLE test (a INT, b INT, c VARCHAR(255))' | psql
[ "$(echo 'SELECT COUNT(*) FROM test' | psql)" = 0 ]
psql <<'EOSQL'
	INSERT INTO test VALUES (1, 2, 'hello')
EOSQL
[ "$(echo 'SELECT COUNT(*) FROM test' | psql)" = 1 ]
psql <<'EOSQL'
	INSERT INTO test VALUES (2, 3, 'goodbye!')
EOSQL
[ "$(echo 'SELECT COUNT(*) FROM test' | psql)" = 2 ]
echo 'DELETE FROM test WHERE a = 1' | psql
[ "$(echo 'SELECT COUNT(*) FROM test' | psql)" = 1 ]
[ "$(echo 'SELECT c FROM test' | psql)" = 'goodbye!' ]
echo 'DROP TABLE test' | psql
