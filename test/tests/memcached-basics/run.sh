#!/bin/bash
set -Eeuo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# for "nc"
clientImage='busybox'
# ensure the clientImage is ready and available
if ! docker image inspect "$clientImage" &> /dev/null; then
	docker pull "$clientImage" > /dev/null
fi

cname="memcached-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

# usage: memcached-command command-line [extra-line ...]
#    ie: memcached-command 'stats'
#        memcached-command 'set a 0 0 2' 'hi'
memcached-command() {
	{
		for line; do
			echo -n "$line"$'\r\n'
		done
	} \
		| docker run --rm -i \
			--link "$cname":memcached \
			"$clientImage" \
			nc memcached 11211 \
		| tr -d '\r'
}

# https://github.com/memcached/memcached/blob/d9dfbe0e2613b9c20cb3c4fdd3c55d1bf3a8c8bd/doc/protocol.txt#L129-L205
memcached-set() {
	local key="$1"; shift
	local flags="$1"; shift
	local exptime="$1"; shift
	local value="$1"; shift

	local bytes="$(echo -n "$value" | wc -c)"

	memcached-command \
		"set $key $flags $exptime $bytes" \
		"$value"
}

# https://github.com/memcached/memcached/blob/d9dfbe0e2613b9c20cb3c4fdd3c55d1bf3a8c8bd/doc/protocol.txt#L213-L247
memcached-get() {
	local key="$1"; shift

	memcached-command \
		"get $key"
}

memcached-conn-test() {
	memcached-command 'stats' > /dev/null
}

. "$dir/../../retry.sh" 'memcached-conn-test'

value='somevalue'
res="$(memcached-set mykey 0 0 "$value")"
exp='STORED'
[ "$res" = "$exp" ]

valLen="$(echo -n "$value" | wc -c)"
res="$(memcached-get mykey)"
exp='VALUE mykey 0 '"$valLen"$'\n'"$value"$'\n''END'
[ "$res" = "$exp" ]
