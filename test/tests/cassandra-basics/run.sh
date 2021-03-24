#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail -o errtrace

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image
clientImage="$image"

# Create an instance of the container-under-test
cid="$(
	docker run -d \
		-e MAX_HEAP_SIZE='128m' \
		-e HEAP_NEWSIZE='32m' \
		-e JVM_OPTS='
			-Dcassandra.ring_delay_ms=0
			-Dcom.sun.management.jmxremote.authenticate=false
			-Dcom.sun.management.jmxremote.port=7199
			-Dcom.sun.management.jmxremote.ssl=false
		' \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT
trap "( set -x; docker logs --tail=20 $cid )" ERR

_status() {
	docker run --rm \
		--link "$cid":cassandra \
		--entrypoint nodetool \
		"$clientImage" \
		-h cassandra status
}

# Make sure our container is up
. "$dir/../../retry.sh" '_status'

cqlsh() {
	docker run -i --rm \
		--link "$cid":cassandra \
		--entrypoint cqlsh \
		"$clientImage" \
		-u cassandra -p cassandra "$@" cassandra
}

# Make sure our container is listening
. "$dir/../../retry.sh" 'cqlsh < /dev/null'

# https://wiki.apache.org/cassandra/GettingStarted#Step_4:_Using_cqlsh

cqlsh -e "
CREATE KEYSPACE mykeyspace
	WITH REPLICATION = {
		'class': 'SimpleStrategy',
		'replication_factor': 1
	}
"

cqlsh -k mykeyspace -e "
CREATE TABLE users (
	user_id int PRIMARY KEY,
	fname text,
	lname text
)
"

cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1745, 'john', 'smith')
"
cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1744, 'john', 'doe')
"
cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1746, 'john', 'smith')
"

# TODO find some way to get cqlsh to provide machine-readable output D:
[[ "$(cqlsh -k mykeyspace -e "
SELECT * FROM users
")" == *'3 rows'* ]]

cqlsh -k mykeyspace -e "
CREATE INDEX ON users (lname)
"
[[ "$(cqlsh -k mykeyspace -e "
SELECT * FROM users WHERE lname = 'smith'
")" == *'2 rows'* ]]
