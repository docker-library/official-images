#!/bin/bash
set -e

# so we can have fancy stuff like !(pattern)
shopt -s extglob

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

library="$dir/../library"
src="$dir/src"
logs="$dir/logs"
namespaces='library stackbrew'

library="$(readlink -f "$library")"
src="$(readlink -f "$src")"
logs="$(readlink -f "$logs")"

# arg handling: all args are [repo|repo:tag]
usage() {
	cat <<EOUSAGE

usage: $0 [options] [repo[:tag] ...]
   ie: $0 --all
       $0 debian ubuntu:12.04

   This script builds the docker images specified using the git repositories
   specified in the library files.

options:
  --help, -h, -?     Print this help message
  --all              Builds all docker repos specified in library
  --no-clone         Don't pull the git repos
  --no-build         Don't build, just echo what would have built
  --library="$library"
                     Where to find repository manifest files
  --src="$src"
                     Where to store the cloned git repositories
  --logs="$logs"
                     Where to store the build logs
  --namespaces="$namespaces"
                     Space separated list of namespaces to tag images in after
                     building

EOUSAGE
}

opts="$(getopt -o 'h?' --long 'all,help,no-build,no-clone,library:,src:,logs:,namespaces:' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

doClone=1
doBuild=1
buildAll=
while true; do
	flag=$1
	shift
	case "$flag" in
		--help|-h|'-?')
			usage
			exit 0
			;;
		--all) buildAll=1 ;;
		--no-clone) doClone= ;;
		--no-build) doBuild= ;;
		--library) library="$1" && shift ;;
		--src) src="$1" && shift ;;
		--logs) logs="$1" && shift ;;
		--namespaces) namespaces="$1" && shift ;;
		--)
			break
			;;
		*)
			{
				echo "error: unknown flag: $flag"
				usage
			} >&2
			exit 1
			;;
	esac
done

repos=()
if [ "$buildAll" ]; then
	repos=( "$library"/!(MAINTAINERS) )
fi
repos+=( "$@" )

repos=( "${repos[@]%/}" )

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'error: no repos specified'
	usage >&2
	exit 1
fi

# globals for handling the repo queue and repo info parsed from library
queue=()
declare -A repoGitRepo=()
declare -A repoGitRef=()
declare -A repoGitDir=()

logDir="$logs/build-$(date +'%Y-%m-%d--%H-%M-%S')"
mkdir -p "$logDir"

latestLogDir="$logs/latest" # this gets shiny symlinks to the latest buildlog for each repo we've seen since the creation of the logs dir
mkdir -p "$latestLogDir"

# gather all the `repo:tag` combos to build
for repoTag in "${repos[@]}"; do
	repo="${repoTag%%:*}"
	tag="${repoTag#*:}"
	[ "$repo" != "$tag" ] || tag=
	
	if [ -f "$repo" ]; then
		repoFile="$repo"
		repo="$(basename "$repoFile")"
		repoTag="${repo}${tag:+:$tag}"
	else
		repoFile="$library/$repo"
	fi
	
	repoFile="$(readlink -f "$repoFile")"
	echo "$repoTag ($repoFile)" >> "$logDir/repos.txt"
	
	if [ "${repoGitRepo[$repoTag]}" ]; then
		queue+=( "$repoTag" )
		continue
	fi
	
	# parse the repo library file
	IFS=$'\n'
	repoTagLines=( $(cat "$repoFile" | grep -vE '^#|^\s*$') )
	unset IFS
	
	tags=()
	for line in "${repoTagLines[@]}"; do
		tag="$(echo "$line" | awk -F ': +' '{ print $1 }')"
		fullGitUrl="$(echo "$line" | awk -F ' +' '{ print $2 }')"
		gitDir="$(echo "$line" | awk -F ' +' '{ print $3 }')"
		
		gitUrl="${fullGitUrl%%@*}"
		gitRef="${fullGitUrl#*@}"
		
		gitRepo="${gitUrl#*://}"
		gitRepo="${gitRepo%/}"
		gitRepo="${gitRepo%.git}"
		gitRepo="${gitRepo%/}"
		gitRepo="$src/$gitRepo"
		
		if [ -z "$doClone" ]; then
			if [ "$doBuild" -a ! -d "$gitRepo" ]; then
				echo >&2 "error: directory not found: $gitRepo"
				exit 1
			fi
		else
			if [ ! -d "$gitRepo" ]; then
				mkdir -p "$(dirname "$gitRepo")"
				echo "Cloning '$gitUrl' into '$gitRepo' ..."
				git clone -q "$gitUrl" "$gitRepo"
				echo 'Cloned successfully!'
			else
				# if we don't have the "ref" specified, "git fetch" in the hopes that we get it
				if ! ( cd "$gitRepo" && git rev-parse --verify "${gitRef}^{commit}" &> /dev/null ); then
					( cd "$gitRepo" && git fetch -q && git fetch -q --tags )
				fi
			fi
			
			# disable any automatic garbage collection too, just to help make sure we keep our dangling commit objects
			( cd "$gitRepo" && git config gc.auto 0 )
		fi
		
		repoGitRepo[$repo:$tag]="$gitRepo"
		repoGitRef[$repo:$tag]="$gitRef"
		repoGitDir[$repo:$tag]="$gitDir"
		tags+=( "$repo:$tag" )
	done
	
	if [ "$repo" = "$repoTag" ]; then
		# add all tags we just parsed
		queue+=( "${tags[@]}" )
	else
		queue+=( "$repoTag" )
	fi
done

set -- "${queue[@]}"
while [ "$#" -gt 0 ]; do
	repoTag="$1"
	gitRepo="${repoGitRepo[$repoTag]}"
	gitRef="${repoGitRef[$repoTag]}"
	gitDir="${repoGitDir[$repoTag]}"
	shift
	if [ -z "$gitRepo" ]; then
		echo >&2 'warning: skipping unknown repo:tag:' "$repoTag"
		continue
	fi
	
	echo "Processing $repoTag ..."
	
	thisLog="$logDir/build-$repoTag.log"
	touch "$thisLog"
	ln -sf "$thisLog" "$latestLogDir/$(basename "$thisLog")"
	
	if ! ( cd "$gitRepo" && git rev-parse --verify "${gitRef}^{commit}" &> /dev/null ); then
		echo "- skipped; invalid ref: $gitRef"
		continue
	fi
	
	( set -x; cd "$gitRepo" && git clean -dfxq && git checkout -q "$gitRef" ) &>> "$thisLog"
	# TODO git tag
	
	IFS=$'\n'
	froms=( $(grep '^FROM[[:space:]]' "$gitRepo/$gitDir/Dockerfile" | awk -F '[[:space:]]+' '{ print $2 ~ /:/ ? $2 : $2":latest" }') )
	unset IFS
	
	for from in "${froms[@]}"; do
		for queuedRepoTag in "$@"; do
			if [ "$from" = "$queuedRepoTag" ]; then
				# a "FROM" in this image is being built later in our queue, so let's bail on this image for now and come back later
				echo "- deferred; FROM $from"
				set -- "$@" "$repoTag"
				continue 3
			fi
		done
	done
	
	if [ "$doBuild" ]; then
		( set -x; cd "$gitRepo/$gitDir" && "$dir/git-set-mtimes" ) &>> "$thisLog"
		
		if ! ( set -x; docker build -t "$repoTag" "$gitRepo/$gitDir" ) &>> "$thisLog"; then
			echo "- failed; see $thisLog"
			continue
		fi
		
		for namespace in $namespaces; do
			( set -x; docker tag "$repoTag" "$namespace/$repoTag" ) &>> "$thisLog"
		done
	fi
done
