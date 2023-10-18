#!/usr/bin/env bash
set -Eeuo pipefail

# the nextcloud tests are very flaky, so the intent of this test is to make sure at least *one* of them is succeeding

dir="$(dirname "$BASH_SOURCE")"
tests="$(dirname "$dir")"

ret=1
for t in \
	nextcloud-cli-mysql \
	nextcloud-cli-postgres \
	nextcloud-cli-sqlite \
; do
	if "$tests/$t/run.sh" "$@"; then
		ret=0
	else
		echo >&2 "note: '$t' failed (only fatal if all three do)"
	fi
done

exit "$ret"
