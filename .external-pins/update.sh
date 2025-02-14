#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$BASH_SOURCE")"

if [ "$#" -eq 0 ]; then
	images="$("$dir/list.sh")"
	set -- $images
fi

for img; do
	echo -n "$img -> "

	if [[ "$img" != *:* ]]; then
		echo >&2 "error: '$img' does not contain ':' -- this violates our assumptions! (did you mean '$img:latest' ?)"
		exit 1
	fi

	digest="$(bashbrew remote arches --json "$img" | jq -r '.desc.digest')"

	imgFile="$("$dir/file.sh" "$img")"
	imgDir="$(dirname "$imgFile")"
	mkdir -p "$imgDir"
	echo "$digest" | tee "$imgFile"
done
