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

	args=(
		-it --rm
	)

	if [ "$pull" = '0' ]; then
		args+=( --name "bashbrew-test-local-$RANDOM" )
	else
		args+=( --name "bashbrew-test-pr-$pull" )
	fi

	args+=(
		-v /var/run/docker.sock:/var/run/docker.sock
		--group-add 0
	)
	if getent group docker &> /dev/null; then
		args+=( --group-add "$(getent group docker | cut -d: -f3)" )
	fi

	# if we don't have DOCKER_HOST set, let's bind-mount cache for speed!
	if [ -z "$DOCKER_HOST" ]; then
		export BASHBREW_CACHE="${BASHBREW_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/bashbrew}" # resolve path to current "host-side" cache directory
		mkdir -p "$BASHBREW_CACHE" # ensure it's created by our user, not root
		export BASHBREW_CACHE="$(cd "$BASHBREW_CACHE" && pwd -P)" # readlink -f
		args+=(
			-v "$BASHBREW_CACHE":/bashbrew-cache
			-e BASHBREW_CACHE=/bashbrew-cache
			# make sure our user in the container can read it
			--group-add "$(stat -c '%g' "$BASHBREW_CACHE")"
		)
	fi

	args+=(
		--user "$(id -u)":"$(id -g)"
		$(id -G | xargs -n1 echo --group-add)
		-v /etc/passwd:/etc/passwd:ro
		-v /etc/group:/etc/group:ro

		-e BASHBREW_DEBUG
		-e BASHBREW_SECOND_STAGE=1
		-w /usr/src/pr
	)

	cmd=( /usr/src/official-images/test-pr.sh "$pull" "$@" )

	exec docker run "${args[@]}" bashbrew "${cmd[@]}"
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

IFS=$'\n'
files=( $(bashbrew list --repos --uniq --build-order "${files[@]}") )
unset IFS

echo 'Build test of' '#'"$pull"';' "$commit" '(`'"$(join '`, `' "${files[@]}")"'`):'
failedBuild=()
failedTests=()
for img in "${files[@]}"; do
	IFS=$'\n'
	uniqImgs=( $(bashbrew list --uniq "$img") )
	unset IFS

	echo
	echo '```console'
	for uniqImg in "${uniqImgs[@]}"; do
		echo
		echo '$ bashbrew build' "$uniqImg"
		if bashbrew build --pull-missing "$uniqImg"; then
			echo
			echo '$ test/run.sh' "$uniqImg"
			if ! ./test/run.sh "$uniqImg"; then
				failedTests+=( "$uniqImg" )
			fi
		else
			failedBuild+=( "$uniqImg" )
		fi
		echo
	done
	echo '```'
done
if [ "${#failedBuild[@]}" -gt 0 ]; then
	echo
	echo 'The following images failed to build:' "${failedBuild[@]}"
fi
if [ "${#failedTests[@]}" -gt 0 ]; then
	echo
	echo 'The following images failed at least one test:' "${failedTests[@]}"
fi
