#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/haskell"
cmd=( "$inContainerPath/container.rb" )

docker run --rm -v "$dir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint runhaskell "$1" "${cmd[@]}"
