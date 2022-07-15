#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

ZOOKEEPER_TEST_SLEEP=3
ZOOKEEPER_TEST_TRIES=5

cname="zookeeper-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

zkCli() {
	docker run --rm -i \
		--link "$cname":zookeeper \
		"$image" \
		zkCli.sh \
		-server zookeeper \
		"$@"
}

. "$dir/../../retry.sh" --tries "$ZOOKEEPER_TEST_TRIES" --sleep "$ZOOKEEPER_TEST_SLEEP" zkCli ls /

# List and check Zookeeper root
zkCli ls / | grep '^\[zookeeper\]$' > /dev/null
