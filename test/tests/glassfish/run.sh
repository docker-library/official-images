#!/bin/bash
set -eo pipefail

serverImage="$1"
containerId="$(docker run -d "$serverImage")"
trap "docker rm -vf $containerId > /dev/null" EXIT

waitForLogLine() {
    timeout="$1";
    logLine="$2";
    until docker logs $containerId 2>&1 | grep -q -E "$logLine"
    do
        if [ $timeout -eq 0 ]
        then
            exit 100;
        fi
        sleep 1
        timeout=$((timeout-1))
    done
}

waitForLogLine 60 '^\s+Eclipse GlassFish\s+[\.0-9]+';
echo "GlassFish started as ${containerId}"

docker stop "${containerId}" &
waitForLogLine 30 '^\s*Completed shutdown of GlassFish runtime';
echo "GlassFish stopped OK!"
