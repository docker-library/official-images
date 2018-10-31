#!/usr/bin/env bash
set -Eeuo pipefail

: "${BASHBREW_CACHE:=$HOME/.cache/bashbrew}"
export BASHBREW_CACHE BASHBREW_ARCH=

if [ ! -d "$BASHBREW_CACHE/git" ]; then
	# initialize the "bashbrew cache"
	bashbrew --arch amd64 from --uniq --apply-constraints hello-world:linux > /dev/null
fi

if [ "$#" -eq 0 ]; then
	set -- '--all'
fi

declare -A naughtyFromsArches=(
	#[img:tag=from:tag]='arch arch ...'
)
naughtyFroms=()

tags="$(bashbrew list --uniq "$@" | sort -u)"
for img in $tags; do
	for BASHBREW_ARCH in $(bashbrew cat --format '{{ join " " .TagEntry.Architectures }}' "$img"); do
		export BASHBREW_ARCH

		if ! from="$(bashbrew cat --format '{{ $.DockerFrom .TagEntry }}' "$img" 2>/dev/null)"; then
			# if we can't fetch the tags from their real locations, let's try the warehouse
			refsList="$(
				bashbrew list --uniq "$img" \
				| sed \
					-e 's!:!/!' \
					-e "s!^!refs/tags/$BASHBREW_ARCH/!" \
					-e 's!$!:!'
			)"
			[ -n "$refsList" ]
			git -C "$BASHBREW_CACHE/git" \
				fetch --no-tags --quiet \
				https://github.com/docker-library/commit-warehouse.git \
				$refsList
			from="$(bashbrew cat --format '{{ $.DockerFrom .TagEntry }}' "$img")"
		fi

		case "$BASHBREW_ARCH=$from" in
			# a few explicitly permissible exceptions to Santa's naughty list
			*=scratch \
			| amd64=docker.elastic.co/elasticsearch/elasticsearch:* \
			| amd64=docker.elastic.co/kibana/kibana:* \
			| amd64=docker.elastic.co/logstash/logstash:* \
			| windows-*=microsoft/nanoserver \
			| windows-*=microsoft/nanoserver:* \
			| windows-*=microsoft/windowsservercore \
			| windows-*=microsoft/windowsservercore:* \
			) continue ;;
		esac

		if ! listOutput="$(bashbrew cat --format '{{ .TagEntry.HasArchitecture arch | ternary arch "" }}' "$from")" || [ -z "$listOutput" ]; then
			if [ -z "${naughtyFromsArches["$img=$from"]:-}" ]; then
				naughtyFroms+=( "$img=$from" )
			else
				naughtyFromsArches["$img=$from"]+=', '
			fi
			naughtyFromsArches["$img=$from"]+="$BASHBREW_ARCH"
		fi
	done
done

for naughtyFrom in "${naughtyFroms[@]:-}"; do
	[ -n "$naughtyFrom" ] || continue # https://mywiki.wooledge.org/BashFAQ/112#BashFAQ.2F112.line-8 (empty array + "set -u" + bash 4.3 == sad day)
	img="${naughtyFrom%%=*}"
	from="${naughtyFrom#$img=}"
	arches="${naughtyFromsArches[$naughtyFrom]}"
	echo " - $img (FROM $from) [$arches]"
done
