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
		# replace "build" steps with something that uses "bashbrew" instead of "docker build"
		# https://github.com/docker-library/bashbrew/blob/a40a54d4d81b9fd2e39b4d7ba3fe203e8b022a67/scripts/github-actions/generate.sh#L74-L93
		| .runs.prepare += "\ngit clone --depth 1 https://github.com/docker-library/bashbrew.git ~/bashbrew\n~/bashbrew/bashbrew.sh --version"
		| .runs.build = (
			(if .os | startswith("windows-") then "export BASHBREW_ARCH=windows-amd64 BASHBREW_CONSTRAINTS=" + ([ .meta.entries[].constraints[] ] | join(", ") | @sh) + "\n" else "" end)
			+ "export BASHBREW_LIBRARY=\"$PWD/library\"\n"
			+ ([ $tags[] | "~/bashbrew/bashbrew.sh build " + @sh ] | join("\n"))
		)
		# use our local clone of official-images for running tests (so test changes can be tested too, if they live in the PR with the image change)
		# https://github.com/docker-library/bashbrew/blob/a40a54d4d81b9fd2e39b4d7ba3fe203e8b022a67/scripts/github-actions/generate.sh#L95
		| .runs.test |= gsub("[^\n\t ]+/run[.]sh "; "./test/run.sh ")
	]' <<<"$newStrategy")"
	jq -c . <<<"$newStrategy" > /dev/null # sanity check
	strategy="$(jq -c '
		# https://stackoverflow.com/a/53666584/433558
		def meld(a; b):
			if (a | type) == "object" and (b | type) == "object" then
				# for some reason, "a" and "b" go out of scope for reduce??
				a as $a | b as $b |
				reduce (a + b | keys_unsorted[]) as $k
					({}; .[$k] = meld($a[$k]; $b[$k]))
			elif (a | type) == "array" and (b | type) == "array" then
				a + b
			elif b == null then
				a
			else
				b
			end;
		meld(.[0]; .[1])
	' <<<"[$strategy,$newStrategy]")"
done
jq -c . <<<"$strategy" > /dev/null # sanity check

if [ -t 1 ]; then
	jq <<<"$strategy"
else
	cat <<<"$strategy"
fi
