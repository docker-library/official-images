#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

# input via HTTP (default port 0.0.0.0:8080)
# output via stdout, newline-delimited nothing-but-the-message
config='
	input {
		http {
		}
	}
	output {
		stdout {
			codec => line {
				format => "%{message}"
			}
		}
	}
'

# Create an instance of the container-under-test
cid="$(docker run -d "$image" -e "$config")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	# https://github.com/docker/docker/issues/14203#issuecomment-129865960 (DOCKER_FIX)
	docker run --rm \
		--link "$cid":logstash \
		-e DOCKER_FIX='                                        ' \
		"$clientImage" \
		curl -fs "$@" "http://logstash:8080"
}

_trimmed() {
	_request "$@" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g'
}

_req-comp() {
	local expected="$1"; shift
	response="$(_trimmed "$@")"
	[ "$response" = "$expected" ]
}

_req-exit() {
	local expectedRet="$1"; shift
	[ "$(_request "$@" --output /dev/null || echo "$?")" = "$expectedRet" ]
}

_req-msg() {
	local msg="$1"; shift
	_req-comp 'ok' --data "$msg"
	# use "retry.sh" to give logstash just a tiny bit of time to actually print the message to stdout
	. "$dir/../../retry.sh" --tries 3 --sleep 0.5 '
		logLine="$(docker logs --tail=1 "$cid")";
		[ "$logLine" = "$msg" ];
	'
}

# Make sure our container is listening
. "$dir/../../retry.sh" --tries 60 '! _req-exit 7' # "Failed to connect to host."

for msg in \
	'hi' \
	"hello $RANDOM world" \
	"hello $RANDOM world" \
	"hello $RANDOM world" \
	'bye' \
; do
	_req-msg "$msg"
done
