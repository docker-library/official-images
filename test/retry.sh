#!/bin/bash

set -e

opts="$(getopt -o 'i:c:t:s:f:' --long 'image:,cid:,tries:,sleep:,fail-expected:' -- "$@")"
eval set -- "$opts"
while true; do
	flag=$1
	shift
	case "$flag" in
		--image|-i) image="$1" && shift ;;
		--cid|-c) cid="$1" && shift ;;
		--tries|-t) tries="$1" && shift ;;
		--sleep|-s) sleep="$1" && shift ;;
		--fail-expected|-f) fail_expected="$1" && shift ;;
		--) break;;
	esac
done

if [ $# -eq 0 ]; then
	echo >&2 'retry.sh requires a command to run'
	false
fi
if [ -n "${fail_expected}" ] && [ -z "$cid" ]; then
	echo >&2 'retry.sh --fail-expected requires --cid option'
	false
fi

: ${tries:=10}
: ${sleep:=2}

while ! eval "$@" &> /dev/null; do
	(( tries-- ))
	if [ $tries -le 0 ]; then
		echo >&2 "${image:-the container} failed to accept connections in a reasonable amount of time!"
		[ "$cid" ] && ( set -x && docker logs "$cid" ) >&2 || true
		eval "$@" # to hopefully get a useful error message
		false
	fi
	if [ "$cid" ] && [ "$(docker inspect -f '{{.State.Running}}' "$cid" 2>/dev/null)" != 'true' ]; then
		if [ -n "${fail_expected}" ]; then
			sleep 1 # added for test stabilization, 'docker logs' sometimes has delay
			docker logs "$cid" 2>&1 \
				| grep -q "${fail_expected}" \
				&& break
			false
		else
			echo >&2 "${image:-the container} stopped unexpectedly!"
			( set -x && docker logs "$cid" ) >&2 || true
			false
		fi
	fi
	echo >&2 -n .
	sleep "$sleep"
done
