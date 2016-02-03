#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

newImage="$("$dir/../image-name.sh" librarytest/ruby-nonroot "$image")"
"$dir/../docker-build.sh" "$dir" "$newImage" <<EOD
FROM $image
USER nobody
EOD

docker run --rm "$newImage" gem install advanced_math

exec "$dir/real-run.sh" "$newImage"
