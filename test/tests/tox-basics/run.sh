#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

newImage="$("$dir/../image-name.sh" librarytest/tox-basics "$image")"
"$dir/../docker-build.sh" "$dir" "$newImage" <<EOD
FROM $image
COPY dir/test.py dir/tox.ini ./
EOD

docker run --rm "$newImage"
