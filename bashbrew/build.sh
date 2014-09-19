#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO config file of some kind
: ${LIBRARY:="$dir/../library"} # where we get the "library/*" repo manifests
: ${SRC:="$dir/src"} # where we clone all the repos, go-style
: ${LOGS:="$dir/logs"} # where "docker build" logs go
: ${NAMESPACES:='library stackbrew'} # after we build, also tag each image as "NAMESPACE/repo:tag"

LIBRARY="$(readlink -f "$LIBRARY")"
SRC="$(readlink -f "$SRC")"
LOGS="$(readlink -f "$LOGS")"

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
  --all              Builds all docker repos specified in LIBRARY
  --no-clone         Don't pull the git repos
  --no-build         Don't build, just echo what would have built

variables:
  # where to find repository manifest files
  LIBRARY="$LIBRARY"

  # where to store the cloned git repositories
  SRC="$SRC"

  # where to store the build logs
  LOGS="$LOGS"

  # which additional namespaces to tag images under
  # NOTE: all images will be tagged in the empty namespace
  NAMESPACES="$NAMESPACES"

EOUSAGE
}

opts="$(getopt -o 'h?' --long 'all,help,no-build,no-clone' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

doClone=1
doBuild=1
buildAll=
while true; do
	flag=$1
	shift
	case "$flag" in
		--help|-h|'-?')
			uasge
			exit 0
			;;
		--all)
			buildAll=1
			;;
		--no-clone)
			doClone=
			;;
		--no-build)
			doBuild=
			;;
		--)
			break
			;;
		*)
			echo >&2 "error: unknown flag: $flag"
			usage >&2
			exit 1
			;;
	esac
done

repos=()
if [ "$buildAll" ]; then
	repos=( $(cd "$LIBRARY" && echo *) )
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

logDir="$LOGS/build-$(date +'%Y-%m-%d--%H-%M-%S')"
mkdir -p "$logDir"
for repo in "${repos[@]}"; do
	echo "$repo" >> "$logDir/repos.txt"
done

latestLogDir="$LOGS/latest" # this gets shiny symlinks to the latest buildlog for each repo we've seen since the creation of the LOGS dir
mkdir -p "$latestLogDir"

# gather all the `repo:tag` combos to build
for repoTag in "${repos[@]}"; do
	if [ "$repoTag" = 'MAINTAINERS' ]; then
		continue
	fi
	
	if [ "${repoGitRepo[$repoTag]}" ]; then
		queue+=( "$repoTag" )
		continue
	fi
	
	repo="${repoTag%:*}"
	
	# parse the repo library file
	IFS=$'\n'
	repoTagLines=( $(cat "$LIBRARY/$repo" | grep -vE '^#|^\s*$') )
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
		gitRepo="$SRC/$gitRepo"
		
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
				( cd "$gitRepo" && git fetch -q && git fetch -q --tags )
			fi
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
	
	if [ "$doClone" ]; then
		( cd "$gitRepo" && git clean -dfxq && git checkout -q "$gitRef" && "$dir/git-set-dir-times" )
		# TODO git tag
		
		IFS=$'\n'
		froms=( $(grep '^FROM[[:space:]]' "$gitRepo/$gitDir/Dockerfile" | awk -F '[[:space:]]+' '{ print $2 ~ /:/ ? $2 : $2":latest" }') )
		unset IFS
		
		for from in "${froms[@]}"; do
			for queuedRepoTag in "$@"; do
				if [ "$from" = "$queuedRepoTag" ]; then
					# a "FROM" in this image is being built later in our queue, so let's bail on this image for now and come back later
					echo "- defer; FROM $from"
					set -- "$@" "$repoTag"
					continue 3
				fi
			done
		done
	fi
	
	if [ "$doBuild" ]; then
		thisLog="$logDir/build-$repoTag.log"
		touch "$thisLog"
		ln -sf "$thisLog" "$latestLogDir/$(basename "$thisLog")"
		docker build -t "$repoTag" "$gitRepo/$gitDir" &> "$thisLog"
		
		for namespace in $NAMESPACES; do
			docker tag "$repoTag" "$namespace/$repoTag"
		done
	fi
done
