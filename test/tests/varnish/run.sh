#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

vname="varnish-volume-$RANDOM-$RANDOM"
trap "docker volume rm $vname > /dev/null" EXIT
docker volume create --driver local \
	--opt type=tmpfs \
	--opt device=tmpfs \
	--opt o=size=100m \
	$vname


cname="varnish-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-v $vname:/var/lib/varnish \
		--name "$cname" \
		"$image" \
		varnishd -F -a 0:0 -f /etc/varnish/default.vcl
)"
trap "docker rm -vf $cid > /dev/null; docker volume rm $vname > /dev/null" EXIT

sidecar() {
	docker run --rm -i \
		--network container:"$cid" \
		-v $vname:/var/lib/varnish \
		"$image" \
		"$@" > /dev/null
}

sidecar varnishlog -d
sidecar varnishncsa -d
sidecar varnishstat -1
sidecar varnishreload
sidecar varnishadm ping
