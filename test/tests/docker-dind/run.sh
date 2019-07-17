#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cname="docker-daemon-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d -it \
		--privileged \
		--name "$cname" \
		-e DOCKER_TLS_CERTDIR=/certs -v /certs \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

docker_() {
	docker run --rm -i \
		--link "$cname":docker \
		-e DOCKER_TLS_CERTDIR=/certs --volumes-from "$cname:ro" \
		--entrypoint docker-entrypoint.sh \
		"$image" \
		"$@"
}

. "$dir/../../retry.sh" --tries 30 'docker_ version'

[ "$(docker_ images -q | wc -l)" = '0' ]
docker_ pull busybox
[ "$(docker_ images -q | wc -l)" = '1' ]

[ "$(docker_ ps -aq | wc -l)" = '0' ]

docker_ run --rm busybox true
docker_ run --rm busybox true
docker_ run --rm busybox true

[ "$(docker_ ps -aq | wc -l)" = '0' ]
docker_ create -i --name test1 busybox cat
[ "$(docker_ ps -aq | wc -l)" = '1' ]

[ "$(docker_ inspect -f '{{.State.Running}}' test1)" = 'false' ]
docker_ start test1
[ "$(docker_ inspect -f '{{.State.Running}}' test1)" = 'true' ]
docker_ stop test1
[ "$(docker_ inspect -f '{{.State.Running}}' test1)" = 'false' ]
docker_ rm test1

[ "$(docker_ ps -aq | wc -l)" = '0' ]
