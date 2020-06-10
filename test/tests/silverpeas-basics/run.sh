#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# run a PostgresSQL container
dbname="postgresql-container-$RANDOM-$RANDOM"
dbid="$(
  docker run -d \
    --name "$dbname" \
    -e POSTGRES_PASSWORD=silverpeas \
    postgres:12.3
)"
trap "docker rm -vf $dbid > /dev/null" EXIT

check_db_running() {
	docker exec "$dbid" psql -U postgres -d 'postgres' -c 'SELECT 1'
}

# wait for PostgreSQL to be ran
. "$dir/../../retry.sh" --tries 20 --sleep 5 'check_db_running'

# create the database for testing Silverpeas
docker exec "$dbid" psql -U postgres -c 'create database silverpeas' > /dev/null

cname="silverpeas-container-$RANDOM-$RANDOM"
# when running the first time, a silverpeas process is spawn before starting Silverpeas
# (this configuration process can take some time)
cid="$(
  docker run -d \
    --name "$cname" \
    --link "$dbid":database \
    -e DB_SERVERTYPE=POSTGRESQL \
    -e DB_NAME=silverpeas \
    -e DB_SERVER=database \
    -e DB_USER=postgres \
    -e DB_PASSWORD=silverpeas \
    "$image"
)"
trap "docker rm -vf $cid $dbid > /dev/null" EXIT

check_running() {
	docker run --rm \
		--link "$cid":silverpeas \
		"$clientImage" \
		curl -fs http://silverpeas:8000/silverpeas > /dev/null
}

# wait for the Silverpeas starting to be completed
. "$dir/../../retry.sh" --tries 20 --sleep 5 'check_running'

expected='Configured: [OK] Running:    [OK] Active:     [OK]  INFO: JBoss is running '
[ "$(docker exec "$cname" /opt/silverpeas/bin/silverpeas status | tr '\n' ' ')" = "$expected" ]
