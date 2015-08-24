#!/bin/bash
set -e

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

tries=10
while ! docker_ version &> /dev/null; do
	(( tries-- ))
	if [ $tries -le 0 ]; then
		echo >&2 'docker daemon failed to accept connections in a reasonable amount of time!'
		( set -x && docker logs "$cid" ) >&2 || true
		docker_ version # to hopefully get a useful error message
		false
	fi
	sleep 2
done

docker_ pull busybox

docker_ run --rm busybox true

docker_ create -i --name test busybox cat
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'false' ]
docker_ start test
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'true' ]
docker_ stop test
[ "$(docker_ inspect -f '{{.State.Running}}' test)" = 'false' ]
docker_ rm test
