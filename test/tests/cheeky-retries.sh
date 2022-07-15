#!/usr/bin/env bash
set -Eeuo pipefail

# intended to be symlinked as "run.sh" next to "real-run.sh" such that we give "real-run.sh" a couple tries to succeed before we give up

dir="$(dirname "$BASH_SOURCE")"

tries=3
while [ "$tries" -gt 0 ]; do
	(( tries-- )) || :
	if "$dir/real-run.sh" "$@"; then
		exit 0
	fi
	if [ "$tries" -gt 0 ]; then
		echo >&2 'warning: failed, retrying'
	fi
done

exit 1
