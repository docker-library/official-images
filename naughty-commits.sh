#!/usr/bin/env bash
set -Eeuo pipefail

fileSizeThresholdMB='2'

: "${BASHBREW_CACHE:=$HOME/.cache/bashbrew}"
export BASHBREW_CACHE BASHBREW_ARCH=

if [ ! -d "$BASHBREW_CACHE/git" ]; then
	# initialize the "bashbrew cache"
	bashbrew --arch amd64 from --uniq --apply-constraints hello-world:linux > /dev/null
fi

_git() {
	git -C "$BASHBREW_CACHE/git" "$@"
}

if [ "$#" -eq 0 ]; then
	set -- '--all'
fi

imgs="$(bashbrew list --repos "$@" | sort -u)"
for img in $imgs; do
	IFS=$'\n'
	commits=( $(
		bashbrew cat --format '
			{{- range $e := .Entries -}}
				{{- range $a := .Architectures -}}
					{{- /* force `git fetch` */ -}}
					{{- $froms := $.ArchDockerFroms $a $e -}}

					{{- $e.ArchGitCommit $a -}}
					{{- "\n" -}}
				{{- end -}}
			{{- end -}}
		' "$img" | sort -u
	) )
	unset IFS

	declare -A naughtyCommits=() naughtyTopCommits=() seenCommits=()
	for topCommit in "${commits[@]}"; do
		IFS=$'\n'
		potentiallyNaughtyGlobs=( '**.tar**' )
		potentiallyNaughtyCommits=( $(_git log --diff-filter=DMT --format='format:%H' "$topCommit" -- "${potentiallyNaughtyGlobs[@]}") )
		unset IFS

		for commit in "${potentiallyNaughtyCommits[@]}"; do
			[ -z "${seenCommits[$commit]:-}" ] || break
			seenCommits[$commit]=1

			IFS=$'\n'
			binaryFiles=( $(
				_git diff-tree --no-commit-id -r --numstat --diff-filter=DMT "$commit" -- "${potentiallyNaughtyGlobs[@]}" \
					| grep '^-' \
					| cut -d$'\t' -f3- \
					|| :
			) )
			unset IFS

			naughtyReasons=()
			for file in "${binaryFiles[@]}"; do
				fileSize="$(_git ls-tree -r --long "$commit" -- "$file" | awk '{ print $4 }')"
				fileSizeMB="$(( fileSize / 1024 / 1024 ))"
				if [ "$fileSizeMB" -gt "$fileSizeThresholdMB" ]; then
					naughtyReasons+=( "modified binary file (larger than ${fileSizeThresholdMB}MB): $file (${fileSizeMB}MB)" )
				fi
			done

			if [ "${#naughtyReasons[@]}" -gt 0 ]; then
				IFS=$'\n'
				naughtyCommits[$commit]="${naughtyReasons[*]}"
				unset IFS
				naughtyTopCommits[$commit]="$topCommit"
			fi
		done
	done

	if [ "${#naughtyCommits[@]}" -gt 0 ]; then
		echo " - $img:"
		for naughtyCommit in "${!naughtyCommits[@]}"; do
			naughtyReasons="${naughtyCommits[$naughtyCommit]}"
			naughtyTopCommit="${naughtyTopCommits[$naughtyCommit]}"
			if [ "$naughtyTopCommit" != "$naughtyCommit" ]; then
				#commitsBetween="$(_git rev-list --count "$naughtyCommit...$naughtyTopCommit")"
				naughtyCommit+=" (in history of $naughtyTopCommit)"
			fi
			echo "   - commit $naughtyCommit:"
			sed -e 's/^/     - /' <<<"$naughtyReasons"
		done
		echo
	fi
done
