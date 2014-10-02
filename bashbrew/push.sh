#!/bin/bash
set -e

# so we can have fancy stuff like !(pattern)
shopt -s extglob

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

library="$dir/../library"
logs="$dir/logs"
namespaces='library stackbrew'

library="$(readlink -f "$library")"
logs="$(readlink -f "$logs")"
# TODO actually log stuff

# arg handling: all args are [repo|repo:tag]
usage() {
	cat <<EOUSAGE

usage: $0 [options] [repo[:tag] ...]
   ie: $0 --all
       $0 debian ubuntu:12.04

   This script pushes the specified docker images from library that are built
   and tagged in the specified namespaces.

options:
  --help, -h, -?     Print this help message
  --all              Pushes all docker images built for the given namespaces
  --no-push          Don't actually push the images to the Docker Hub
  --library="$library"
                     Where to find repository manifest files
  --namespaces="$namespaces"
                     Space separated list of namespaces to tag images in after
                     building

EOUSAGE
}

opts="$(getopt -o 'h?' --long 'help,all,no-push,library:,logs:,namespaces:' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

doPush=1
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
		--no-push) doPush= ;;
		--library) library="$1" && shift ;;
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
	
	# parse the repo library file
	IFS=$'\n'
	tagList=( $(awk -F ': +' '!/^#|^\s*$/ { print $1 }' "$repoFile") )
	unset IFS
	
	tags=()
	for tag in "${tagList[@]}"; do
		tags+=( "$repo:$tag" )
	done
	
	pushes=()
	if [ "$repo" = "$repoTag" ]; then
		pushes=( "${tags[@]}" )
	else
		pushes+=( "$repoTag" )
	fi
	
	for pushTag in "${pushes[@]}"; do
		for namespace in $namespaces; do
			if [ "$doPush" ]; then
				if ! docker push "$namespace/$pushTag"; then
					echo >&2 "- $namespace/$pushTag failed to push!"
				fi
			else
				echo "docker push" "$namespace/$pushTag"
			fi
		done
	done
done
