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

pgImage='postgres:12.3'
if ! docker image inspect "$pgImage" &> /dev/null; then
	docker pull "$pgImage" > /dev/null
fi

dbuser='postgres'
dbpass="silver-$RANDOM-$RANDOM"
dbdatabase='silverpeas'

# run a PostgresSQL container
dbname="postgresql-container-$RANDOM-$RANDOM"
docker run -d \
	--name "$dbname" \
	-e POSTGRES_PASSWORD=$dbpass \
	-e POSTGRES_DB=$dbdatabase \
	"$pgImage"
trap "docker rm -vf $dbname > /dev/null" EXIT

check_db_running() {
	docker run \
		--rm \
		--link "$dbname":pg \
		-e PGPASSWORD="$dbpass" \
		"$pgImage" \
		psql \
		--host pg \
		--username "$dbuser" \
		--dbname "$dbdatabase" \
		-c 'SELECT 1'
}

# wait for PostgreSQL to be ready outside of container localhost
. "$dir/../../retry.sh" --tries 20 --sleep 5 'check_db_running'

# when running the first time, a silverpeas process is spawn before starting Silverpeas
# (this configuration process can take some time)
cname="silverpeas-container-$RANDOM-$RANDOM"
docker run -d \
	--name "$cname" \
	--link "$dbname":pg \
	-e DB_SERVER=pg \
	-e DB_SERVERTYPE=POSTGRESQL \
	-e DB_NAME="$dbdatabase" \
	-e DB_USER="$dbuser" \
	-e DB_PASSWORD="$dbpass" \
	"$image"
trap "docker rm -vf $cname $dbname > /dev/null" EXIT

check_running() {
	docker run --rm \
		--link "$cname":silverpeas \
		"$clientImage" \
		curl -fs http://silverpeas:8000/silverpeas > /dev/null
}

# wait for the Silverpeas starting to be completed
. "$dir/../../retry.sh" --tries 20 --sleep 10 'check_running'

expected='Configured: [OK] Running:    [OK] Active:     [OK]  INFO: JBoss is running '
[ "$(docker exec "$cname" /opt/silverpeas/bin/silverpeas status | tr '\n' ' ')" = "$expected" ]
