#!/bin/bash
set -eo pipefail

# TODO something clever with this pattern to get the exact list of _tags_ which have changed, not just repos:
#format='{{ range .Entries }}{{ join " " (join ":" $.RepoName (.Tags | first)) .GitRepo .GitFetch .GitCommit .Directory }}{{ "\n" }}{{ end }}'
#comm -13 \
#	<(bashbrew cat -f "$format" https://github.com/docker-library/official-images/raw/master/library/docker | sort) \
#	<(bashbrew cat -f "$format" https://raw.githubusercontent.com/infosiftr/stackbrew/d92ffa4b5f8a558c22c5d0a7e0f33bff8fae990b/library/docker | sort) \
#	| cut -d' ' -f1

# make sure we can GTFO
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# start with an error if Docker isn't working...
docker version > /dev/null

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
	dockerRepo='oisupport/bashbrew'
	dockerBase="$dockerRepo:base"
	dockerImage="$dockerRepo:test-pr"

	bashbrewVersion="$(< "$dir/bashbrew-version")"
	docker build -t "$dockerBase" --pull "https://github.com/docker-library/bashbrew.git#v$bashbrewVersion" > /dev/null
	docker build -t "$dockerImage" "$dir" > /dev/null

	args=( --init )

	if [ "$pull" = '0' ]; then
		args+=( --name "bashbrew-test-local-$RANDOM" )
	else
		args+=( --name "bashbrew-test-pr-$pull" )
	fi

	args+=(
		-v /var/run/docker.sock:/var/run/docker.sock
		--group-add 0

		-v /etc/passwd:/etc/passwd:ro
		-v /etc/group:/etc/group:ro
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
	else
		dockerGid="$(
			docker run -i --rm "${args[@]}" "$dockerImage" sh -e <<-'EOSH'
				exec 2>/dev/null
				stat -c '%g' /var/run/docker.sock \
					|| getent group docker | cut -d: -f3
			EOSH
		)" || true
		if [ "$dockerGid" ]; then
			args+=( --group-add "$dockerGid" )
		fi
	fi

	args+=(
		--user "$(id -u)":"$(id -g)"
		$(id -G | xargs -n1 echo --group-add)

		-e BASHBREW_SECOND_STAGE=1
	)

	for e in "${!BASHBREW_@}"; do
		case "$e" in
			BASHBREW_SECOND_STAGE|BASHBREW_CACHE|BASHBREW_LIBRARY) ;;
			*)
				args+=( -e "$e" )
				;;
		esac
	done

	cmd=( ./test-pr.sh "$pull" "$@" )

	if [ -t 0 ] && [ -t 1 ]; then
		# only add "-t" if we have a TTY
		args+=( -t )
	fi

	exec docker run -i --rm "${args[@]}" "$dockerImage" "${cmd[@]}"
fi

if [ -d .git ]; then
	echo >&2 'error: something has gone horribly wrong; .git already exists'
	echo >&2 '  why do you have BASHBREW_SECOND_STAGE set?'
	exit 1
fi

if [ "$pull" = '0' ]; then
	commit='FAKE'
else
	dir="$(mktemp -d)"
	trap "rm -rf '$dir'" EXIT
	cd "$dir"

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

export BASHBREW_LIBRARY="$PWD/library"

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

echo 'Build test of' '#'"$pull"';' "$commit"';' '`'"${BASHBREW_ARCH:-amd64}"'`' '(`'"$(join '`, `' "${files[@]}")"'`):'
declare -A failedBuild=() failedTests=()
for img in "${files[@]}"; do
	IFS=$'\n'
	uniqImgs=( $(bashbrew list --uniq --build-order "$img") )
	uniqImgs=( $(bashbrew cat --format '{{ if .TagEntry.HasArchitecture arch }}{{ $.RepoName }}:{{ .TagEntry.Tags | first }}{{ end }}' "${uniqImgs[@]}") ) # filter to just the set supported by the current BASHBREW_ARCH
	unset IFS

	echo
	echo '```console'
	for uniqImg in "${uniqImgs[@]}"; do
		imgRepo="${uniqImg%%:*}"
		echo
		echo '$ bashbrew build' "$uniqImg"
		if bashbrew build --pull=missing "$uniqImg"; then
			echo
			echo '$ test/run.sh' "$uniqImg"
			if ! ./test/run.sh "$uniqImg"; then
				failedTests[$imgRepo]+=" $uniqImg"
			fi
		else
			failedBuild[$imgRepo]+=" $uniqImg"
		fi
		echo
	done
	echo '```'
done
echo
if [ "${#failedBuild[@]}" -gt 0 ]; then
	echo 'The following images failed to build:'
	echo
	for repo in "${!failedBuild[@]}"; do
		echo '- `'"$repo"'`:'
		for img in ${failedBuild[$repo]}; do
			echo '  - `'"$img"'`'
		done
	done
	echo
fi
if [ "${#failedTests[@]}" -gt 0 ]; then
	echo
	echo 'The following images failed at least one test:'
	echo
	for repo in "${!failedTests[@]}"; do
		echo '- `'"$repo"'`:'
		for img in ${failedTests[$repo]}; do
			echo '  - `'"$img"'`'
		done
	done
	echo
fi
