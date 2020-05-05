#!/usr/bin/env bash
set -Eeuo pipefail
  
bashbrewDir="$1"; shift

if [ "$#" -eq 0 ]; then
	git fetch --quiet https://github.com/docker-library/official-images.git master
	changes="$(git diff --numstat FETCH_HEAD...HEAD -- library/ | cut -d$'\t' -f3-)"
	repos="$(xargs -rn1 basename <<<"$changes")"
	set -- $repos
fi

strategy='{}'
for repo; do
	newStrategy="$(GITHUB_REPOSITORY="$repo" GENERATE_STACKBREW_LIBRARY='cat "library/$GITHUB_REPOSITORY"' "$bashbrewDir/scripts/github-actions/generate.sh")"
	newStrategy="$(jq -c --arg repo "$repo" '.matrix.include = [
		.matrix.include[]
		| ([ .meta.entries[].tags[0] ]) as $tags
		| .name = ($tags | join(", "))
		| .runs.prepare += "\ngit clone --depth 1 https://github.com/docker-library/bashbrew.git ~/bashbrew\n~/bashbrew/bashbrew.sh --version"
		| .runs.build = (
			(if .os | startswith("windows-") then "export BASHBREW_ARCH=windows-amd64 BASHBREW_CONSTRAINTS=" + ([ .meta.entries[].constraints[] ] | join(", ") | @sh) + "\n" else "" end)
			+ "export BASHBREW_LIBRARY=\"$PWD/library\"\n"
			+ ([ $tags[] | "~/bashbrew/bashbrew.sh build " + @sh ] | join("\n"))
		)
	]' <<<"$newStrategy")"
	jq -c . <<<"$newStrategy" > /dev/null # sanity check
	strategy="$(jq -c --argjson strategy "$strategy" '.matrix.include = ($strategy.matrix.include // []) + .matrix.include' <<<"$newStrategy")"
done
jq -c . <<<"$strategy" > /dev/null # sanity check

if [ -t 1 ]; then
	jq <<<"$strategy"
else
	cat <<<"$strategy"
fi
