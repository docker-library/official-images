#!/bin/bash
set -eo pipefail

serverImage="$1"
containerId="$(docker run -d "$serverImage")"
trap "docker rm -vf $containerId > /dev/null" EXIT

logLine='^\s+Eclipse GlassFish\s+[\.0-9]+'
timeout=60

until docker logs $containerId 2>&1 | grep -q -E "$logLine"
do
    if [ $timeout -eq 0 ]
    then
        exit 100;
    fi
    sleep 1
    timeout=$((timeout-1))
done

echo "Success!"
