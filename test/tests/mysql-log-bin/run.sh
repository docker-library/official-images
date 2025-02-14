#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="mysql-container-$RANDOM-$RANDOM"
rootpass="secret$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ROOT_PASSWORD="$rootpass" \
		--name "$cname" \
		"$image" \
		--log-bin="foo-$RANDOM" \
		--server-id="$RANDOM"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

mysql() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint sh \
		"$image" \
		-euc 'if command -v mariadb > /dev/null; then exec mariadb "$@"; else exec mysql "$@"; fi' -- \
		-uroot \
		-p"$rootpass" \
		-hmysql \
		--silent \
		"$@"
}

. "$dir/../../retry.sh" --tries 30 "echo 'SELECT 1' | mysql"

# yay, must be OK
