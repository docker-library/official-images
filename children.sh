#!/bin/bash
set -eu -o pipefail

# "bashbrew children" can't work with "--uniq" and "bashbrew build" will build the entire "tag group", so we need to filter the output to just uniq values

: "${BASHBREW:=bashbrew}"

IFS=$'\n'
set -- $("$BASHBREW" list --uniq --repos --build-order --apply-constraints "$@")

# \o/ https://github.com/docker-library/official-images/commit/9e57342714f99074ec205eea668c8b73aada36ec
comm -13 \
		<("$BASHBREW" list "$@" | sort -u) \
		<("$BASHBREW" children --apply-constraints "$@" | sort -u) \
	| xargs --no-run-if-empty "$BASHBREW" list --build-order --apply-constraints --uniq
exit 0

children=( $("$BASHBREW" children --apply-constraints "$@") )

[ "${#children[@]}" -gt 0 ] || exit 0

# just repo names so we can get the right build-order for all of their tags
childrenRepos=( $(echo "${children[*]}" | cut -d: -f1 | sort -u) )

# all uniq tags from all repos which have relevant children, in proper build order
childrenReposUniq=( $("$BASHBREW" list --uniq --build-order --apply-constraints "${childrenRepos[@]}") )

# the canonical ("uniq") versions of the children we're after (same as the values now in "childrenReposUniq")
#   use "comm" to suppress "$@" from the list of children we care about
childrenUniq=(
	$(
		comm -13 \
			<(
				"$BASHBREW" list --uniq "$@" \
					| sort -u
			) \
			<(
				"$BASHBREW" list --uniq "${children[@]}" \
					| sort -u
			)
	)
)

[ "${#childrenUniq[@]}" -gt 0 ] || exit 0

unset IFS

# create a lookup table of whether we should return a particular tag
declare -A wantChild=()
for child in "${childrenUniq[@]}"; do
	wantChild["$child"]=1
done

# loop over the canonical build order and print out tags we want :)
for child in "${childrenReposUniq[@]}"; do
	[ "${wantChild[$child]:-}" ] || continue
	echo "$child"
done

# note that we can't use "comm" by itself here because "childrenUniq" and "childrenReposUniq" are not in the same order, which "comm" requires
