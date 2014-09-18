#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO config file of some kind
: ${LIBRARY:="$dir/../library"} # where we get the "library/*" repo manifests
: ${SRC:="$dir/src"} # where we clone all the repos, go-style
: ${LOGS:="$dir/logs"} # where "docker build" logs go
: ${NAMESPACES:='library stackbrew'} # after we build, also tag each image as "NAMESPACE/repo:tag"

# arg handling: all args are [repo|repo:tag]
# no argument means build all repos in $LIBRARY
repos=( "$@" )
if [ ${#repos[@]} -eq 0 ]; then
	repos=( $(cd "$LIBRARY" && echo *) )
fi
repos=( "${repos[@]%/}" )

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
		
		if [ ! -d "$gitRepo" ]; then
			mkdir -p "$(dirname "$gitRepo")"
			echo "Cloning '$gitUrl' into '$gitRepo' ..."
			git clone -q "$gitUrl" "$gitRepo"
			echo 'Cloned successfully!'
		else
			( cd "$gitRepo" && git fetch -q && git fetch -q --tags )
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
	if [ -z "$gitRepo" -o -z "$gitRef" ]; then
		continue
	fi
	
	echo "Processing $repoTag ..."
	( cd "$gitRepo" && git clean -dfxq && git checkout -q "$gitRef" && "$dir/git-set-dir-times" )
	
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
	
	thisLog="$logDir/build-$repoTag.log"
	touch "$thisLog"
	ln -sf "$thisLog" "$latestLogDir/$(basename "$thisLog")"
	docker build -t "$repoTag" "$gitRepo/$gitDir" &> "$thisLog"
	
	for namespace in $NAMESPACES; do
		docker tag "$repoTag" "$namespace/$repoTag"
	done
done
