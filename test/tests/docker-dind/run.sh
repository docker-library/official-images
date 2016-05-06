#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="docker-daemon-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d -it \
		--privileged \
		--name "$cname" \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

docker_() {
	docker run --rm -i \
		--link "$cname":docker \
		--entrypoint docker-entrypoint.sh \
		"$image" \
		"$@"
}

. "$dir/../../retry.sh" 'docker_ version'

docker_ pull busybox

docker_ run --rm busybox true

docker_ create -i --name test busybox cat
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'false' ]
docker_ start test
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'true' ]
docker_ stop test
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'false' ]
docker_ rm test
