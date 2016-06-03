#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

usage() {
	cat <<-EOUSAGE
		usage: $0 [PR number] [repo[:tag]]
		   ie: $0 1024
		       $0 9001 debian php django
		       $0 0 hylang # special case that runs against local directory
		
		This script builds and tests the specified pull request to official-images and
		provides ouput in markdown for commenting on the pull request.
	EOUSAGE
}

pull="$1"
shift || { usage >&2 && exit 1; }

if [ -z "$BASHBREW_SECOND_STAGE" ]; then
	docker build --pull -t bashbrew "$dir" > /dev/null

	if [ "$pull" = '0' ]; then
		name="bashbrew-test-local-$RANDOM"
	else
		name="bashbrew-test-pr-$pull"
	fi

	exec docker run \
		-it --rm \
		--name "$name" \
		-e BASHBREW_SECOND_STAGE=1 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e BASHBREW_VERBOSE \
		-w /usr/src/pr \
		bashbrew /usr/src/official-images/test-pr.sh "$pull" "$@"

	# TODO somehow reconcile remote hosts so we can re-use our cache from invocation to invocation :(
	# -v "${BASHBREW_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/bashbrew}":/bashbrew-cache
fi

if [ -d .git ]; then
	echo >&2 'error: something has gone horribly wrong; .git already exists'
	echo >&2 '  why do you have BASHBREW_SECOND_STAGE set?'
	exit 1
fi

if [ "$pull" = '0' ]; then
	cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
	commit='FAKE'
else
	# TODO we only have "git version 2.4.1" which doesn't support "clone -q" :(
	git init -q .
	git remote add origin https://github.com/docker-library/official-images.git
	git fetch -q origin
	git reset -q --hard origin/master
	git config user.name 'nobody'
	git config user.email 'nobody@nowhere.noplace'
	git fetch -q origin "pull/$pull/head:pr-$pull"
	git merge -q --no-edit "pr-$pull" > /dev/null

	commit="$(git log -1 --format=format:%h "pr-$pull")"
fi

if [ "$#" -eq 0 ]; then
	IFS=$'\n'
	files=( $(git diff --name-only origin/master...HEAD -- library | xargs -n1 basename) )
	unset IFS

	# TODO narrow this down into groups of the exact tags for each image that changed >:)
else
	files=( "$@" )
fi

if [ ${#files[@]} -eq 0 ]; then
	echo >&2 'no files in library/ changed in PR #'"$pull"
	exit 0
fi

join() {
	sep="$1"
	arg1="$2"
	shift 2
	echo -n "$arg1"
	[ $# -gt 0 ] && printf "${sep}%s" "$@"
}

#IFS=$'\n'
#files=( $(bashbrew list --build-order "${files[@]}") )
#unset IFS

echo 'Build test of' '#'"$pull"';' "$commit" '(`'"$(join '`, `' "${files[@]}")"'`):'
failed=
for img in "${files[@]}"; do
	echo
	echo '```console'
	echo '$ bashbrew build "'"$img"'"'
	if bashbrew build --pull-missing "$img"; then
		echo '$ bashbrew list --uniq "$url" | xargs test/run.sh'
		if ! bashbrew list --uniq "$img" | xargs ./test/run.sh; then
			failed=1
		fi
	else
		failed=1
	fi
	echo '```'
done
if [ "$failed" ]; then
	echo
	echo 'There is at least one failure in the above build log.'
fi
