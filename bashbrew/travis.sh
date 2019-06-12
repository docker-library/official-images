#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

repos=( --all )
extraCommands=

upstreamRepo='docker-library/official-images'
upstreamBranch='master'
if [ "$TRAVIS_PULL_REQUEST" -a "$TRAVIS_PULL_REQUEST" != 'false' ]; then
	upstreamRepo="$TRAVIS_REPO_SLUG"
	upstreamBranch="$TRAVIS_BRANCH"
fi

HEAD="$(git rev-parse --verify HEAD)"

git fetch -q "https://github.com/$upstreamRepo.git" "refs/heads/$upstreamBranch"
UPSTREAM="$(git rev-parse --verify FETCH_HEAD)"

if [ "$TRAVIS_BRANCH" = 'master' -a "$TRAVIS_PULL_REQUEST" = 'false' ]; then
	# if we're testing master itself, RUN ALL THE THINGS
	echo >&2 'Testing master -- BUILD ALL THE THINGS!'
elif [ "$(git diff --numstat "$UPSTREAM...$HEAD" -- . | wc -l)" -ne 0 ]; then
	# changes in bashbrew/ -- keep "--all" so we test the bashbrew script changes appropriately
	echo >&2 'Changes in bashbrew/ detected!'
	#extraCommands=1 # TODO this takes a lot of load and often fails (force pushes to maintainer branches, etc)
else
	repos=( $(git diff --numstat "$UPSTREAM...$HEAD" -- ../library | awk -F '/' '{ print $2 }') )
	extraCommands=1
fi

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'Skipping test builds: no changes to library/ or bashbrew/ in PR'
	exit
fi

export BASHBREW_LIBRARY="$(dirname "$PWD")/library"

if badTags="$(bashbrew list "${repos[@]}" | grep -E ':.+latest.*|:.*latest.+')" && [ -n "$badTags" ]; then
	echo >&2
	echo >&2 "Incorrectly formatted 'latest' tags detected:"
	echo >&2 ' ' $badTags
	echo >&2
	echo >&2 'Read https://github.com/docker-library/official-images#tags-and-aliases for more details.'
	echo >&2
	exit 1
fi

if [ -n "$extraCommands" ] && naughtyFrom="$(../naughty-from.sh "${repos[@]}")" && [ -n "$naughtyFrom" ]; then
	echo >&2
	echo >&2 "Invalid 'FROM' + 'Architectures' combinations detected:"
	echo >&2
	echo >&2 "$naughtyFrom"
	echo >&2
	echo >&2 'Read https://github.com/docker-library/official-images#multiple-architectures for more details.'
	echo >&2
	exit 1
fi

if [ -n "$extraCommands" ] && naughtyConstraints="$(../naughty-constraints.sh "${repos[@]}")" && [ -n "$naughtyConstraints" ]; then
	echo >&2
	echo >&2 "Invalid 'FROM' + 'Constraints' combinations detected:"
	echo >&2
	echo >&2 "$naughtyConstraints"
	echo >&2
	exit 1
fi

_bashbrew() {
	echo $'\n\n$ bashbrew' "$@" "${repos[@]}"
	bashbrew "$@" "${repos[@]}"
}

_bashbrew list
_bashbrew list --uniq
_bashbrew cat
if [ -n "$extraCommands" ]; then
	_bashbrew list --build-order
	_bashbrew from
fi
echo; echo
