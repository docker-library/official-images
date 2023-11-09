#!/bin/bash
set -e

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

testName="$(basename "$testDir")"
newImage="$("$runDir/image-name.sh" "librarytest/$testName" "$image")"
"$runDir/docker-build.sh" "$testDir" "$newImage" <<EOD
FROM $image
COPY dir/container.swift /
RUN swiftc /container.swift -o container
CMD [ "/container" ]
EOD

docker run --rm "$newImage"
