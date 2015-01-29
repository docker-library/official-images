#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/haskell"
cmd=( "$inContainerPath/container.hs" )

docker run --rm -v "$dir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint runhaskell "$1" "${cmd[@]}"
