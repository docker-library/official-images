#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

newImage="$("$dir/../image-name.sh" librarytest/redis-basics-persistent "$image")"
"$dir/../docker-build.sh" "$dir" "$newImage" <<EOD
FROM $image
CMD ["--appendonly", "yes"]
EOD

exec "$dir/real-run.sh" "$newImage"
