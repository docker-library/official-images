#!/bin/bash
set -e

pass="$(docker run --rm --entrypoint awk "$1" -F ':' '$1 == "root" { print $2 }' /etc/passwd)"
if [ "$pass" = 'x' ]; then
	pass="$(docker run --rm --entrypoint awk --user root "$1" -F ':' '$1 == "root" { print $2 }' /etc/shadow)"
fi
[ -z "$pass" -o "$pass" = '*' ]
