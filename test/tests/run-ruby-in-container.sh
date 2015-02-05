#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/ruby"
cmd=( "$inContainerPath/container.rb" )

docker run --rm -v "$dir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint ruby "$1" "${cmd[@]}"
