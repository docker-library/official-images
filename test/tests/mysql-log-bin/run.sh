#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ALLOW_EMPTY_PASSWORD=1 \
		--name "$cname" \
		"$image" \
		--log-bin="foo-$RANDOM" \
		--server-id="$RANDOM"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

mysql() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint mysql \
		"$image" \
		-uroot \
		-hmysql \
		--silent \
		"$@"
}

. "$dir/../../retry.sh" --tries 30 "echo 'SELECT 1' | mysql"

# yay, must be OK
