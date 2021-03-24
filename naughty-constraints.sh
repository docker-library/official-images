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

_windows_constraint() {
	local from="$1"; shift
	local repo="${from%:*}"
	local tag="${from#$repo:}"

	local constraint
	case "$repo" in
		mcr.microsoft.com/windows/nanoserver | microsoft/nanoserver) constraint='nanoserver' ;;
		mcr.microsoft.com/windows/servercore | microsoft/windowsservercore) constraint='windowsservercore' ;;
		*) echo >&2 "error: unknown Windows image: $from"; exit 1 ;;
	esac

	if [ "$tag" != 'latest' ]; then
		constraint+="-$tag"
	fi

	echo "$constraint"
}

_expected_constraints() {
	local from="$1"; shift

	local fromConstraints
	if fromConstraints="$(bashbrew cat --format '{{ .TagEntry.Constraints | join "\n" }}' "$from" 2>/dev/null)" && [ -n "$fromConstraints" ]; then
		echo "$fromConstraints"
		return
	fi

	case "$from" in
		*microsoft*) _windows_constraint "$from" ;;
	esac

	return
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
	constraints="$(bashbrew cat --format '{{ .TagEntry.Constraints | join "\n" }}' "$img" | sort -u)"
	declare -A imgMissing=()
	declare -A imgExtra=()
	for BASHBREW_ARCH in $arches; do
		export BASHBREW_ARCH

		froms="$(_froms "$img")"
		[ -n "$froms" ] # rough sanity check

		allExpected=
		for from in $froms; do
			expected="$(_expected_constraints "$from")"
			allExpected="$(sort -u <<<"$allExpected"$'\n'"$expected")"
		done
		missing="$(comm -13 <(echo "$constraints") <(echo "$allExpected"))"
		if [ -n "$missing" ]; then
			imgMissing[$from]+=$'\n'"$missing"
		fi
		extra="$(comm -23 <(echo "$constraints") <(echo "$allExpected"))"
		if [ -n "$extra" ]; then
			imgExtra[$from]+=$'\n'"$extra"
		fi
	done
	if [ "${#imgMissing[@]}" -gt 0 ]; then
		for from in $(IFS=$'\n'; sort -u <<<"${!imgMissing[*]}"); do
			missing="${imgMissing[$from]}"
			missing="$(sed '/^$/d' <<<"$missing" | sort -u)"
			echo " - $img -- missing constraints (FROM $from):"
			sed 's/^/   - /' <<<"$missing"
		done
	fi
	if [ "${#imgExtra[@]}" -gt 0 ]; then
		for from in $(IFS=$'\n'; sort -u <<<"${!imgExtra[*]}"); do
			extra="${imgExtra[$from]}"
			extra="$(sed '/^$/d' <<<"$extra" | sort -u)"
			echo " - $img -- extra constraints (FROM $from):"
			sed 's/^/   - /' <<<"$extra"
		done
	fi
done
