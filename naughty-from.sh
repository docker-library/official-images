#!/usr/bin/env bash
set -Eeuo pipefail

export BASHBREW_ARCH=

if [ "$#" -eq 0 ]; then
	set -- '--all'
fi

externalPinsDir="$(dirname "$BASH_SOURCE")/.external-pins"
declare -A externalPinsArchesCache=(
	#[img:tag]='["arch","arch",...]' # (json array of strings)
)

# custom error message (for why Ubuntu 25.10+ does not support riscv64)
message=''

_is_naughty() {
	local from="$1"; shift

	# DOI cannot support riscv64 on Ubuntu 25.10+ since it uses RVA23 and hardware does not exist yet
	# > For Ubuntu 25.10 release we plan to raise the required RISC-V ISA profile family to RVA23
	# https://bugs.launchpad.net/ubuntu/+source/ubuntu-release-upgrader/+bug/2111715
	if [ "$BASHBREW_ARCH" = 'riscv64' ] && [[ "$from" == 'ubuntu:'* ]]; then
		normalized="$(bashbrew list --uniq "$from")" # catch when latest changes
		case "$normalized" in
			ubuntu:22.04 | ubuntu:24.04 | ubuntu:25.04 | ubuntu:jammy* | ubuntu:noble* | ubuntu:plucky*)
				# these are fine, let the rest of the tests try them
				;;
			*)
				# ubuntu 25.10+, uses riscv64 with RVA23
				# unsupported in DOI until hardware is acquired
				message='DOI cannot support riscv64 on Ubuntu 25.10+ since it uses RVA23 and hardware does not exist yet'
				return 0
				;;
		esac
	fi

	case "$from" in
		# "scratch" isn't a real image and is always permissible (on non-Windows)
		scratch)
			case "$BASHBREW_ARCH" in
				windows-*) return 0 ;; # can't use "FROM scratch" on Windows
				*)         return 1 ;; # can use "FROM scratch" everywhere else
			esac
			;;

		*/*)
			# must be external, let's check our pins for acceptability
			local externalPinFile="$externalPinsDir/${from/:/___}" # see ".external-pins/list.sh"
			if [ -s "$externalPinFile" ]; then
				local digest
				digest="$(< "$externalPinFile")"
				from+="@$digest"
			else
				# not pinned, must not be acceptable
				return 0
			fi
			;;
	esac

	case "$from" in
		*/*@sha256:*)
			if [ -z "${externalPinsArchesCache["$from"]:-}" ]; then
				local remoteArches
				if remoteArches="$(bashbrew remote arches --json "$from" | jq -c '.arches | keys')"; then
					externalPinsArchesCache["$from"]="$remoteArches"
				else
					echo >&2 "warning: failed to query supported architectures of '$from'"
					externalPinsArchesCache["$from"]='[]'
				fi
			fi
			if jq <<<"${externalPinsArchesCache["$from"]}" -e 'index(env.BASHBREW_ARCH)' > /dev/null; then
				# hooray, a supported architecture!
				return 1
			fi
			;;

		*)
			# must be some other official image AND support our current architecture
			local archSupported
			if archSupported="$(bashbrew cat --format '{{ .TagEntry.HasArchitecture arch | ternary arch "" }}' "$from")" && [ -n "$archSupported" ]; then
				return 1
			fi
			;;
	esac

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

tags="$(bashbrew --namespace '' list --uniq "$@" | sort -u)"
for img in $tags; do
	arches="$(_arches "$img")"
	hasNice= # do we have _any_ arches that aren't naughty? (so we can make the message better if not)
	for BASHBREW_ARCH in $arches; do
		export BASHBREW_ARCH

		froms="$(_froms "$img")"
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

if [ -n "$message" ]; then
	echo " - $message"
fi
