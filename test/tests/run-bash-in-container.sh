#!/bin/bash
set -e

dir="$(readlink -f "$(dirname "$BASH_SOURCE")")"

inContainerPath="/tmp/bash"
cmd=( "$inContainerPath/container.sh" )

docker run --rm -v "$dir":"$inContainerPath":ro -w "$inContainerPath" --entrypoint bash "$1" "${cmd[@]}"
