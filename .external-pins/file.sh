#!/usr/bin/env bash
set -Eeuo pipefail

# given an image (name:tag), return the appropriate filename

dir="$(dirname "$BASH_SOURCE")"

for img; do
	if [[ "$img" != *:* ]]; then
		echo >&2 "error: '$img' does not contain ':' -- this violates our assumptions! (did you mean '$img:latest' ?)"
		exit 1
	fi

	imgFile="$dir/${img/:/___}" # see ".external-pins/list.sh"
	echo "$imgFile"
done
