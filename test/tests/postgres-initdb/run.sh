#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

serverImage="$("$dir/../image-name.sh" librarytest/postgres-initdb "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/initdb.sql /docker-entrypoint-initdb.d/
EOD

export POSTGRES_USER='my cool postgres user'
export POSTGRES_PASSWORD='my cool postgres password'
export POSTGRES_DB='my cool postgres database'

cname="postgres-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e POSTGRES_USER \
		-e POSTGRES_PASSWORD \
		-e POSTGRES_DB \
		--name "$cname" \
		"$serverImage"
)"
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

[ "$(echo 'SELECT COUNT(*) FROM test' | psql)" = 1 ]
[ "$(echo 'SELECT c FROM test' | psql)" = 'goodbye!' ]
