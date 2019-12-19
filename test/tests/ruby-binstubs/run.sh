#!/bin/bash
set -eo pipefail

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
runDir="$(dirname "$testDir")"

"$runDir/run-in-container.sh" "$testDir" "$1" sh ./container.sh 2.0.2
"$runDir/run-in-container.sh" "$testDir" "$1" sh ./container.sh 2.1.1
