#!/bin/bash
set -e

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"
# TODO make this work for ibmjava too (jre or sfj -> sdk)
jdk="${image/jre/jdk}"

volume="$(docker volume create)"
trap "docker volume rm '$volume' &> /dev/null" EXIT

# jdk image to build java class
"$runDir/run-in-container.sh" \
	--docker-arg "--volume=$volume:/container/" \
	-- \
	"$testDir" \
	"$jdk" \
	javac -d /container/ ./container.java

# jre image to run class
"$runDir/run-in-container.sh" \
	--docker-arg "--volume=$volume:/container/" \
	-- \
	"$testDir" \
	"$image" \
	java -cp /container/ container
