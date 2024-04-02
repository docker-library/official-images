#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -eq 0 ]; then
	git fetch --quiet https://github.com/docker-library/official-images.git master
	changes="$(git diff --no-renames --name-only --diff-filter='d' FETCH_HEAD...HEAD -- library/)"
	repos="$(xargs -rn1 basename <<<"$changes")"
	set -- $repos
fi

if [ "$#" -eq 0 ]; then
	echo >&2 'No library/ changes detected, skipping.'
	exit
fi

export BASHBREW_LIBRARY="$PWD/library"

bashbrew from --uniq "$@" > /dev/null

numNaughty=0

if badTags="$(bashbrew list "$@" | grep -E ':.+latest.*|:.*latest.+')" && [ -n "$badTags" ]; then
	echo >&2
	echo >&2 "Incorrectly formatted 'latest' tags detected:"
	echo >&2 ' ' $badTags
	echo >&2
	echo >&2 'Read https://github.com/docker-library/official-images#tags-and-aliases for more details.'
	echo >&2
	(( ++numNaughty ))
fi

naughtySharedTags="$(./naughty-sharedtags.sh "$@")"
if [ -n "$naughtySharedTags" ]; then
	echo >&2
	echo >&2 "Invalid 'SharedTags' combinations detected:"
	echo >&2
	echo >&2 "$naughtySharedTags"
	echo >&2
	echo >&2 'Read https://github.com/docker-library/faq#whats-the-difference-between-shared-and-simple-tags for more details.'
	echo >&2
	(( ++numNaughty ))
fi

naughtyFrom="$(./naughty-from.sh "$@")"
if [ -n "$naughtyFrom" ]; then
	echo >&2
	echo >&2 "Invalid 'FROM' + 'Architectures' combinations detected:"
	echo >&2
	echo >&2 "$naughtyFrom"
	echo >&2
	echo >&2 'Read https://github.com/docker-library/official-images#multiple-architectures for more details.'
	echo >&2
	(( ++numNaughty ))
fi

naughtyConstraints="$(./naughty-constraints.sh "$@")"
if [ -n "$naughtyConstraints" ]; then
	echo >&2
	echo >&2 "Invalid 'FROM' + 'Constraints' combinations detected:"
	echo >&2
	echo >&2 "$naughtyConstraints"
	echo >&2
	(( ++numNaughty ))
fi

naughtyCommits="$(./naughty-commits.sh "$@")"
if [ -n "$naughtyCommits" ]; then
	echo >&2
	echo >&2 "Unpleasant commits detected:"
	echo >&2
	echo >&2 "$naughtyCommits"
	echo >&2
	(( ++numNaughty ))
fi

exit "$numNaughty"
