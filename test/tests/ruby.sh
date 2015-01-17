#!/bin/bash
set -e

for artifact in "$(dirname "$(readlink -f "$BASH_SOURCE")")"/ruby-artifacts/*; do
	inContainerPath="/tmp/$(basename "$artifact")"
	case "$artifact" in
		*.rb) cmd=( ruby "$inContainerPath" ) ;;
		*.sh) cmd=( "$inContainerPath" ) ;;
		*)    continue ;;
	esac
	if ! ret="$(docker run --rm -v "$artifact":"$inContainerPath":ro "$1" "${cmd[@]}")"; then
		echo >&2 "error: '$artifact' failed! got $ret"
		exit 1
	fi
	if [ "$ret" != "ok" ]; then
		echo >&2 "error: expected 'ok', got '$ret'"
		exit 1
	fi
done
