#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

app1id="$(docker run -d "$image" rapidoid.port=80 id=app1 app.services=ping,status)"
app2id="$(docker run -d "$image" rapidoid.port=80 id=app2 app.services=ping,status)"

proxyid="$(docker run -d --link "$app1id":app1 --link "$app2id":app2 "$image" rapidoid.port=80 '/ -> http://app1, http://app2' app.services=ping)"

trap "docker rm -vf $proxyid $app1id $app2id > /dev/null" EXIT

_request() {
	local cid="$1"
	shift

	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":rapidoid \
		"$clientImage" \
		curl -fs -X"$method" "$@" "http://rapidoid/$url"
}

# Make sure all Rapidoid servers are listening on port 80
for cid in $app1id $app2id $proxyid; do
	. "$dir/../../retry.sh" --tries 40 --sleep 0.25 '[ "$(_request '$cid' GET /rapidoid/ping --output /dev/null || echo $?)" != 7 ]'
done

# Make sure that the round-robin load balancing works properly
for n in `seq 1 5`; do
	for i in 1 2; do
		[[ "$(_request $cid GET "/rapidoid/status")" == *"\"app$i\""* ]]
	done
done
