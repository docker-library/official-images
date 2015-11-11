#!/bin/bash
set -e

# wrapper around "docker build" that creates a temporary directory and copies files into it first so that arbitrary host directories can be copied into containers without bind mounts, but accepts a Dockerfile on stdin

# usage: ./docker-build.sh some-host-directory -t some-new-image:some-tag <<EOD
#        FROM ...
#        COPY dir/... /.../
#        EOD
#    ie: ./docker-build.sh .../hylang-hello-world -t librarytest/hylang <<EOD
#        FROM hylang
#        COPY dir/container.hy /dir/
#        CMD ["hy", "/dir/container.hy"]
#        EOD

dir="$1"; shift
[ -d "$dir" ]

tmp="$(mktemp -t -d docker-library-test-build-XXXXXXXXXX)"
trap "rm -rf '$tmp'" EXIT

cat > "$tmp/Dockerfile"
cp -a "$dir" "$tmp/dir"
docker build "$@" "$tmp" > /dev/null
