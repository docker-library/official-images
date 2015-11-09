#!/bin/bash
set -e

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

source "$runDir/run-in-container.sh" "$testDir" "$1" sh -c 'gcc -o /container ./container.c && exec /container'
