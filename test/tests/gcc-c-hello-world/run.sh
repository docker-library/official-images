#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/c'

docker run --rm -v "$dirTest":"$dirContainer":rw -w "$dirContainer" "$image" gcc -o hello-world  hello-world.c
"$dirTest"/hello-world
rm -rf "$dirTest"/hello-world
