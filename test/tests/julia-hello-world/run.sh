#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/julia'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" julia hello-world.jl
