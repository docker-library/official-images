#!/usr/bin/env bash
set -Eeuo pipefail

# a mimic of "bashbrew cat" which should sort slightly more deterministically (so even full-order-changing PRs should have reasonable diffs)

images="$(
	bashbrew list --repos --uniq "$@" \
		| sort -uV \
		| xargs -r bashbrew list --repos --uniq --build-order
)"
set -- $images

declare -A seenGlobal=()

first=1
for img; do
	if [ -n "$first" ]; then
		first=
	else
		echo; echo
	fi

	if [ "$#" -gt 1 ]; then
		echo "# $img"
	fi

	repo="${img%:*}"
	if [ -z "${seenGlobal["$repo"]:-}" ]; then
		bashbrew cat --format '{{ printf "%s\n" (.Manifest.Global.ClearDefaults defaults) }}' "$img"
		seenGlobal["$repo"]="$img"
	else
		echo "# (see also ${seenGlobal["$repo"]} above)"
	fi

	bashbrew list --uniq "$img" \
		| sort -V \
		| xargs -r bashbrew list --uniq --build-order \
		| xargs -r bashbrew cat --format '
			{{- range $e := .TagEntries -}}
				{{- printf "\n%s\n" ($e.ClearDefaults $.Manifest.Global) -}}
			{{- end -}}
		'
done
