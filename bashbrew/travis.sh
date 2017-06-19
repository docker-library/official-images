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
	extraCommands=1
else
	repos=( $(git diff --numstat "$UPSTREAM...$HEAD" -- ../library | awk -F '/' '{ print $2 }') )
	extraCommands=1
fi

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'Skipping test builds: no changes to library/ or bashbrew/ in PR'
	exit
fi

export BASHBREW_LIBRARY="$(dirname "$PWD")/library"

cmds=(
	'list'
	'list --uniq'
	'cat'
)
if [ "$extraCommands" ]; then
	cmds+=(
		'list --build-order'
		'from --apply-constraints'
	)
fi

export PS4=$'\n\n$ '
for cmd in "${cmds[@]}"; do
	( set -x && bashbrew $cmd "${repos[@]}" )
done
echo; echo
