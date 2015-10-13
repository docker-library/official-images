#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/c'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" sh -c 'gcc -o /hello-world hello-world.c && /hello-world'
