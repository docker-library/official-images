#!/usr/bin/env bash
set -Eeuo pipefail

dir='.external-pins'

if [ "$#" -eq 0 ]; then
	images="$(find "$dir" -type f -printf '%P\n' | sort)"
	set -- $images
fi

for img; do
	echo -n "$img -> "
	digest="$(bashbrew remote arches --json "$img" | jq -r '.desc.digest')"

	imgDir="$(dirname "$dir/$img")"
	mkdir -p "$imgDir"
	echo "$digest" | tee "$dir/$img"
done
