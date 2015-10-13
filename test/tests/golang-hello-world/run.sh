#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/hello-world'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" sh -c 'go build -o /hello-world hello-world.go && /hello-world'
