#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/cpp'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" sh -c 'g++ -o /hello-world hello-world.cpp && /hello-world'
