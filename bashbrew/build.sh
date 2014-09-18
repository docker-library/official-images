#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO config file of some kind
: ${LIBRARY:="$dir/../library"} # where we get the "library/*" repo manifests

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
		
		repoGitRepo[$repo:$tag]="$gitUrl"
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

echo "${queue[@]}"
# TODO clone and build
