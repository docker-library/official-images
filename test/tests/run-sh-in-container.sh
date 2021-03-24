#!/usr/bin/env bash
set -Eeuo pipefail

testDir="$(dirname "$BASH_SOURCE")"
testDir="$(readlink -f "$testDir")"
runDir="$(readlink -f "$BASH_SOURCE")"
runDir="$(dirname "$runDir")"

case "$1" in
	*windowsservercore* | *nanoserver*)
		[ -f "$testDir/container.cmd" ]
		source "$runDir/run-in-container.sh" "$testDir" "$1" cmd /Q /S /C '.\container.cmd'
		;;

	*)
		[ -f "$testDir/container.sh" ]
		source "$runDir/run-in-container.sh" "$testDir" "$1" sh ./container.sh
		;;
esac
