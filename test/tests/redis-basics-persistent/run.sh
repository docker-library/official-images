#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="redis-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

redis-cli() {
	docker run --rm -i \
		--link "$cname":redis \
		--entrypoint redis-cli \
		"$image" \
		-h redis \
		"$@"
}

# http://redis.io/topics/quickstart#check-if-redis-is-working

. "$dir/../../retry.sh" --tries 20 '[ "$(redis-cli ping)" = "PONG" ]'

[ "$(redis-cli set mykey somevalue)" = 'OK' ]
[ "$(redis-cli get mykey)" = 'somevalue' ]

docker stop "$cname"
docker start "$cname"

. "$dir/../../retry.sh" --tries 20 '[ "$(redis-cli ping)" = "PONG" ]'

[ "$(redis-cli get mykey)" = 'somevalue' ]
