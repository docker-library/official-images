#!/usr/bin/env bash
set -Eeuo pipefail

fileSizeThresholdMB='2'

export BASHBREW_ARCH=

gitCache="$(bashbrew cat --format '{{ gitCache }}' <(echo 'Maintainers: empty hack (@example)'))"
_git() {
	git -C "$gitCache" "$@"
}

if [ "$#" -eq 0 ]; then
	set -- '--all'
fi

imgs="$(bashbrew list --repos "$@" | sort -u)"
for img in $imgs; do
	bashbrew fetch "$img" # force `git fetch`
	commits="$(
		bashbrew cat --format '
			{{- range $e := .Entries -}}
				{{- range $a := .Architectures -}}
					{
						{{- json "GitRepo" }}:{{ json ($e.ArchGitRepo $a) -}},
						{{- json "GitFetch" }}:{{ json ($e.ArchGitFetch $a) -}},
						{{- json "GitCommit" }}:{{ json ($e.ArchGitCommit $a) -}}
					}
					{{- "\n" -}}
				{{- end -}}
			{{- end -}}
		' "$img" | jq -s 'unique'
	)"

	declare -A naughtyCommits=() naughtyTopCommits=() seenCommits=()
	length="$(jq -r 'length' <<<"$commits")"
	for (( i = 0; i < length; i++ )); do
		topCommit="$(jq -r ".[$i].GitCommit" <<<"$commits")"
		gitRepo="$(jq -r ".[$i].GitRepo" <<<"$commits")"
		gitFetch="$(jq -r ".[$i].GitFetch" <<<"$commits")"

		if ! _git fetch --quiet "$gitRepo" "$gitFetch:" ; then
			naughtyCommits[$topCommit]="unable to to fetch specified GitFetch: $gitFetch"
			naughtyTopCommits[$topCommit]="$topCommit"
		elif ! _git merge-base --is-ancestor "$topCommit" 'FETCH_HEAD'; then
			# check that the commit is in the GitFetch branch specified
			naughtyCommits[$topCommit]="is not in the specified ref GitFetch: $gitFetch"
			naughtyTopCommits[$topCommit]="$topCommit"
		fi

		IFS=$'\n'
		potentiallyNaughtyGlobs=( '**.tar**' )
		potentiallyNaughtyCommits=( $(_git log --diff-filter=DMT --format='format:%H' "$topCommit" -- "${potentiallyNaughtyGlobs[@]}") )
		unset IFS

		# bash 4.3 sucks (https://stackoverflow.com/a/7577209/433558)
		[ "${#potentiallyNaughtyCommits[@]}" -gt 0 ] || continue

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

			# bash 4.3 sucks (https://stackoverflow.com/a/7577209/433558)
			[ "${#binaryFiles[@]}" -gt 0 ] || continue

			naughtyReasons=()
			for file in "${binaryFiles[@]}"; do
				fileSize="$(_git ls-tree -r --long "$commit" -- "$file" | awk '{ print $4 }')"
				fileSizeMB="$(( fileSize / 1024 / 1024 ))"
				if [ "$fileSizeMB" -gt "$fileSizeThresholdMB" ]; then
					naughtyReasons+=( "modified binary file (larger than ${fileSizeThresholdMB}MB): $file (${fileSizeMB}MB)" )
				fi
			done

			if [ "${#naughtyReasons[@]}" -gt 0 ]; then
				: "${naughtyCommits[$commit]:=}"
				if [ -n "${naughtyCommits[$commit]}" ]; then
					naughtyCommits[$commit]+=$'\n'
				fi
				IFS=$'\n'
				naughtyCommits[$commit]+="${naughtyReasons[*]}"
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
