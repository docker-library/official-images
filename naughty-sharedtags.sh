#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -eq 0 ]; then
	set -- '--all'
fi

bashbrew cat --format '
	{{- range $e := .Entries -}}
		{{- range $t := .SharedTags -}}
			{{- "{" -}}
				"sharedTag": {{ join ":" $.RepoName $t | json }},
				"tag": {{ join ":" $.RepoName ($e.Tags | first) | json }},
				"arches": {{ $e.Architectures | json }}
			{{- "}\n" -}}
		{{- end -}}
	{{- end -}}
' "$@" | jq -rn '
	# collect map of "shared tag -> all architectures" (combining shared tags back together, respecting/keeping duplicates, since that is what this is testing for)
	reduce inputs as $in ({}; .[$in.sharedTag] |= (. // {} | .arches += $in.arches | .tags += [$in.tag]))
	# convert that into a map of "shared tags -> same architecture list" (just to shrink the problem set and make it easier to look at/think about)
	| reduce to_entries[] as $in ([];
		(path(first(.[] | select(.value.arches == $in.value.arches))) // [length]) as $i
		| .[$i[0]] |= (
			.key |= if . then "\(.), \($in.key)" else $in.key end
			| .value //= $in.value
		)
	)
	| map(
		# filter down to just entries with duplicates (ignoring Windows duplicates, since duplicating them is the primary use case of SharedTags in the first place)
		.value.arches |= (
			# TODO we *should* try to further verify that there is only one copy of each underlying Windows version here (not 2x "ltsc2022" for example), but that is a much more difficult query to automate
			. - ["windows-amd64"]
			# trim the list down to just the duplicates (so the error is more obvious)
			| group_by(.)
			| map(select(length > 1))
			| flatten
		)
		| select(.value.arches | length > 0)
		| " - \(.key): (duplicate architectures in SharedTags; \(.value.tags | join(", ")))\([ "", .value.arches[] ] | join("\n   - "))"
	)
	| join("\n\n")
'
