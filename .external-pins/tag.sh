#!/usr/bin/env bash
set -Eeuo pipefail

# given a filename, return the appropriate image (name:tag)

origDir="$(dirname "$BASH_SOURCE")"
dir="$(readlink -ve "$origDir")"

for file; do
	abs="$(readlink -vm "$file")"
	rel="${abs#$dir/}"
	rel="${rel##*.external-pins/}" # in case we weren't inside "$dir" but the path is legit
	if [ "$rel" = "$abs" ]; then
		echo >&2 "error: '$file' is not within '$origDir'"
		echo >&2 "('$abs' vs '$dir')"
		exit 1
	fi

	img="${rel/___/:}" # see ".external-pins/list.sh"
	if [ "$img" = "$rel" ]; then
		echo >&2 "error: '$file' does not contain ':' ('___') -- this violates our assumptions!"
		exit 1
	fi

	echo "$img"
done
