#!/usr/bin/env bash
set -Eeuo pipefail

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"
# TODO make this work for ibmjava too (jre or sfj -> sdk)
jdk="${image/jre/jdk}"

newImage="$("$runDir/image-name.sh" librarytest/java-hello-world "$image")"
"$runDir/docker-build.sh" "$testDir" "$newImage" <<EOD
FROM $jdk AS jdk
WORKDIR /container
COPY dir/container.java ./
RUN javac ./container.java
FROM $image
COPY --from=jdk /container /container
WORKDIR /container
EOD

docker run --rm "$newImage" java -cp . container
