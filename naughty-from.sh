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

_is_naughty() {
	local from="$1"; shift

	case "$BASHBREW_ARCH=$from" in
		# a few images that no longer exist (and are thus not permissible)
		# https://techcommunity.microsoft.com/t5/Containers/Removing-the-latest-Tag-An-Update-on-MCR/ba-p/393045
		*=mcr.microsoft.com/windows/nanoserver:latest \
		| *=mcr.microsoft.com/windows/servercore:latest \
		| *=microsoft/nanoserver:latest \
		| *=microsoft/windowsservercore:latest \
		) return 0 ;;

		# a few explicitly permissible exceptions to Santa's naughty list
		*=scratch \
		| amd64=docker.elastic.co/elasticsearch/elasticsearch:* \
		| amd64=docker.elastic.co/kibana/kibana:* \
		| amd64=docker.elastic.co/logstash/logstash:* \
		| windows-*=mcr.microsoft.com/windows/nanoserver:* \
		| windows-*=mcr.microsoft.com/windows/servercore:* \
		| windows-*=microsoft/nanoserver:* \
		| windows-*=microsoft/windowsservercore:* \
		) return 1 ;;

		# "x/y" and not an approved exception
		*/*) return 0 ;;
	esac

	# must be some other official image AND support our current architecture
	local archSupported
	if archSupported="$(bashbrew cat --format '{{ .TagEntry.HasArchitecture arch | ternary arch "" }}' "$from")" && [ -n "$archSupported" ]; then
		return 1
	fi

	return 0
}

_arches() {
	bashbrew cat --format '
		{{- range .TagEntries -}}
			{{- .Architectures | join "\n" -}}
			{{- "\n" -}}
		{{- end -}}
	' "$@" | sort -u
}

_froms() {
	bashbrew cat --format '
		{{- range .TagEntries -}}
			{{- $.DockerFroms . | join "\n" -}}
			{{- "\n" -}}
		{{- end -}}
	' "$@" | sort -u
}

declare -A naughtyFromsArches=(
	#[img:tag=from:tag]='arch arch ...'
)
naughtyFroms=()
declare -A allNaughty=(
	#[img:tag]=1
)

tags="$(bashbrew list --uniq "$@" | sort -u)"
for img in $tags; do
	arches="$(_arches "$img")"
	hasNice= # do we have _any_ arches that aren't naughty? (so we can make the message better if not)
	for BASHBREW_ARCH in $arches; do
		export BASHBREW_ARCH

		if ! froms="$(_froms "$img" 2>/dev/null)"; then
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
			froms="$(_froms "$img")"
		fi

		[ -n "$froms" ] # rough sanity check

		for from in $froms; do
			if _is_naughty "$from"; then
				if [ -z "${naughtyFromsArches["$img=$from"]:-}" ]; then
					naughtyFroms+=( "$img=$from" )
				else
					naughtyFromsArches["$img=$from"]+=', '
				fi
				naughtyFromsArches["$img=$from"]+="$BASHBREW_ARCH"
			else
				hasNice=1
			fi
		done
	done

	if [ -z "$hasNice" ]; then
		allNaughty["$img"]=1
	fi
done

for naughtyFrom in "${naughtyFroms[@]:-}"; do
	[ -n "$naughtyFrom" ] || continue # https://mywiki.wooledge.org/BashFAQ/112#BashFAQ.2F112.line-8 (empty array + "set -u" + bash 4.3 == sad day)
	img="${naughtyFrom%%=*}"
	from="${naughtyFrom#$img=}"
	if [ -n "${allNaughty["$img"]:-}" ]; then
		echo " - $img (FROM $from) -- completely unsupported base!"
	else
		arches="${naughtyFromsArches[$naughtyFrom]}"
		echo " - $img (FROM $from) [$arches]"
	fi
done
