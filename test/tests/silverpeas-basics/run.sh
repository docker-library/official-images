#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'

cname="silverpeas-container-$RANDOM-$RANDOM"
# when running the first time, a silverpeas process is spawn before starting Silverpeas
# (this configuration process can take some time)
cid="$(
	docker run -d \
		--name "$cname" \
		-e DB_SERVERTYPE='H2' \
		-e DB_SERVER=':file:' \
		-e DB_PASSWORD='sa' \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

check_running() {
	docker run --rm \
		--link "$cid":silverpeas \
		"$clientImage" \
		curl -fs http://silverpeas:8000/silverpeas > /dev/null
}

. "$dir/../../retry.sh" --tries 20 --sleep 5 'check_running'

expected='Configured: [OK] Running:    [OK] Active:     [OK]  INFO: JBoss is running '
[ "$(docker exec "$cname" /opt/silverpeas/bin/silverpeas status | tr '\n' ' ')" = "$expected" ]
