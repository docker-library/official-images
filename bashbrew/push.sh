#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# TODO config file of some kind
: ${LIBRARY:="$dir/../library"} # where we get the "library/*" repo manifests
: ${LOGS:="$dir/logs"} # where "docker build" logs go
: ${NAMESPACES:='library stackbrew'} # after we build, also tag each image as "NAMESPACE/repo:tag"

LIBRARY="$(readlink -f "$LIBRARY")"
LOGS="$(readlink -f "$LOGS")"
# TODO actually log stuff

# arg handling: all args are [repo|repo:tag]
usage() {
	cat <<EOUSAGE

usage: $0 [options] [repo[:tag] ...]
   ie: $0 --all
       $0 debian ubuntu:12.04

   This script pushes the specified docker images from LIBRARY that are built
   and tagged in the specified NAMESPACES.

options:
  --help, -h, -?     Print this help message
  --all              Pushes all docker images built for the given NAMESPACES

variables:
  # where to find repository manifest files
  LIBRARY="$LIBRARY"

  # which namespaces to push
  NAMESPACES="$NAMESPACES"

EOUSAGE
}

# TODO impove arg hanlding for complex args; ex: --exclude=repo:tag
if [ "$1" = '--help' -o "$1" = '-h' -o "$1" = '-?' ]; then
	usage
	exit 0
fi

if [ "$1" = '--all' ]; then
	repos=( $(cd "$LIBRARY" && echo *) )
else
	repos=( "$@" )
fi
repos=( "${repos[@]%/}" )

if [ "${#repos[@]}" -eq 0 ]; then
	echo >&2 'error: no repos specified'
	usage >&2
	exit 1
fi

# this is to prevent parsing a manifest twice
declare -A validRepo=()

doPush() {
	for repoTag in "$@"; do
		for namespace in $NAMESPACES; do
			# TODO get rid of the echo and actually push
			echo "docker push" "$namespace/$repoTag"
		done
	done
}

for repoTag in "${repos[@]}"; do
	if [ "$repoTag" = 'MAINTAINERS' ]; then
		continue
	fi
	
	if [ "${validRepo[$repoTag]}" ]; then
		doPush "$repoTag"
		continue
	fi
	
	repo="${repoTag%:*}"
	
	# parse the repo library file
	IFS=$'\n'
	tagList=( $(awk -F ': +' '!/^#|^\s*$/ { print $1 }' "$LIBRARY/$repo") )
	unset IFS
	
	tags=()
	for tag in "${tagList[@]}"; do
		validRepo[$repo:$tag]=1
		tags+=( "$repo:$tag" )
	done
	
	if [ "$repo" = "$repoTag" ]; then
		doPush "${tags[@]}"
	elif [ "${validRepo[$repoTag]}" ]; then
		doPush "$repoTag"
	else
		echo >&2 "warning: specified repo is not in the LIBRARY, skipping: $repoTag"
	fi
done
