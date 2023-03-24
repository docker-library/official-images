#!/bin/bash

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

newImage="$("$dir/../image-name.sh" librarytest/tox-derivative "$image")"
"$dir/../docker-build.sh" "$dir" "$newImage" <<EOD
FROM $image
USER root
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3.12; \
    rm -rf /var/lib/apt/lists/*
USER tox
COPY dir/test.py dir/tox.ini ./
EOD

docker run --rm "$newImage"
