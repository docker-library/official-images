#!/bin/bash
set -e

volume="$(docker volume create)"
trap "docker volume rm '$volume' &> /dev/null" EXIT

docker run --rm --volume="$volume:/znc-data" "$1" --makepem
docker run --rm --volume="$volume:/znc-data" --entrypoint=grep "$1" 'BEGIN RSA PRIVATE KEY' /znc-data/znc.pem
