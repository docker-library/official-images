#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/usr/src/ruby'

docker run -it --rm -v "$dirTest":"$dirContainer" -w "$dirContainer" "$image" ruby hello-world.rb
