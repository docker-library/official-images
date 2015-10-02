#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/node'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" node hello-world.js
