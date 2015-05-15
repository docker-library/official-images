#!/bin/bash
set -e

pass="$(docker run --rm --entrypoint awk "$1" -F ':' '$1 == "root" { print $2 }' /etc/passwd)"

if [ "$pass" = 'x' ]; then
	# 'x' means password is in /etc/shadow instead
	pass="$(docker run --rm --entrypoint awk --user root "$1" -F ':' '$1 == "root" { print $2 }' /etc/shadow)"
fi

if [ -z "$pass" -o "$pass" = '*' ]; then
	# '*' and '' mean no password
	exit 0
fi

if [ "${pass:0:1}" = '!' ]; then
	# '!anything' means "locked" password
	echo >&2 "warning: locked password detected for root: '$pass'"
	exit 0
fi

if [ "${pass:0:1}" = '$' ]; then
	# gotta be crypt ($id$salt$encrypted), must be a fail
	echo >&2 "error: crypt password detected for root: '$pass'"
	exit 1
fi

echo >&2 "warning: garbage password detected for root: '$pass'"
exit 0
