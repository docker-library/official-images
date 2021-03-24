#!/bin/bash

set -e

opts="$(getopt -o 'i:c:t:s:' --long 'image:,cid:,tries:,sleep:' -- "$@")"
eval set -- "$opts"
while true; do
	flag=$1
	shift
	case "$flag" in
		--image|-i) image="$1" && shift ;;
		--cid|-c) cid="$1" && shift ;;
		--tries|-t) tries="$1" && shift ;;
		--sleep|-s) sleep="$1" && shift ;;
		--) break;;
	esac
done

if [ $# -eq 0 ]; then
	echo >&2 'retry.sh requires a command to run'
	false
fi

: ${tries:=10}
: ${sleep:=2}

while ! eval "$@" &> /dev/null; do
	(( tries-- ))
	if [ $tries -le 0 ]; then
		echo >&2 "${image:-the container} failed to accept connections in a reasonable amount of time!"
		[ "$cid" ] && ( set -x && docker logs "$cid" ) >&2 || true
		( set -x && eval "$@" ) >&2 || true # to hopefully get a useful error message
		false
	fi
	if [ "$cid" ] && [ "$(docker inspect -f '{{.State.Running}}' "$cid" 2>/dev/null)" != 'true' ]; then
		echo >&2 "${image:-the container} stopped unexpectedly!"
		( set -x && docker logs "$cid" ) >&2 || true
		false
	fi
	echo >&2 -n .
	sleep "$sleep"
done
