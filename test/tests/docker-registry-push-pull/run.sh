#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"
case "${image##*/}" in
	docker:*dind*)
		dockerImage="$image"
		registryImage='registry'
		;;
	registry:*|registry)
		registryImage="$image"
		dockerImage='docker:dind'
		;;
	*)
		echo >&2 "error: unable to determine whether '$image' is registry or docker:dind"
		exit 1
		;;
esac

rhostname='reg.example.com'
rnamespace="${rhostname}:5000"

rcname="docker-registry-container-$RANDOM-$RANDOM"
rcid="$(
	docker run -d -it \
		--hostname "$rhostname" \
		--name "$rcname" \
		"$registryImage"
)"
trap "docker rm -vf $rcid > /dev/null" EXIT

dcname="docker-daemon-container-$RANDOM-$RANDOM"
dcid="$(
	docker run -d -it \
		--privileged \
		--link "$rcid":"$rhostname" \
		--name "$dcname" \
		"$dockerImage" \
		--insecure-registry "$rnamespace"
)"
trap "docker rm -vf $rcid $dcid > /dev/null" EXIT

docker_() {
	docker run --rm -i \
		--link "$dcid":docker \
		--entrypoint docker-entrypoint.sh \
		"$dockerImage" \
		"$@"
}

. "$dir/../../retry.sh" 'docker_ version'

[ "$(docker_ images -q | wc -l)" = '0' ]
docker_ pull busybox
[ "$(docker_ images -q | wc -l)" = '1' ]

docker_ tag busybox "$rnamespace/busybox"
docker_ push "$rnamespace/busybox"

docker_ rmi busybox "$rnamespace/busybox"
[ "$(docker_ images -q | wc -l)" = '0' ]
docker_ pull "$rnamespace/busybox"
[ "$(docker_ images -q | wc -l)" = '1' ]

docker_ run --rm "$rnamespace/busybox" true
