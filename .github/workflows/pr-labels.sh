#!/usr/bin/env bash
set -Eeuo pipefail

git fetch --quiet https://github.com/docker-library/official-images.git master

changes="$(git diff --numstat FETCH_HEAD...HEAD -- library/ | cut -d$'\t' -f3-)"
set -- $changes

if [ "$#" -eq 0 ]; then
	echo >&2 'No library/ changes detected, skipping labels.'
	exit
fi

if newImages="$(git diff --name-only --diff-filter=A FETCH_HEAD...HEAD -- "$@")" && [ -n "$newImages" ]; then
	echo >&2
	echo >&2 "NEW IMAGES: $newImages"
	echo >&2
	set -- "$@" 'new-image'
fi

IFS=$'\n'
echo "$*"
