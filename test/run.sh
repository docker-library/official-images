#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

self="$(basename "$0")"

usage() {
	cat <<EOUSAGE

usage: $self [-t test ...] [imageTag ...]
   ie: $self debian:wheezy
       $self -t utc python:3-onbuild
       $self -t utc python:3-onbuild -t py-onbuild

This script processes the specified docker images to test their running
environments.
EOUSAGE
}

# arg handling
opts="$(getopt -o 'ht:?' --long 'dry-run,help,test:' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

tests=()
dryRun=
while true; do
	flag=$1
	shift
	case "$flag" in
		--dry-run)  dryRun=1 ;;
		--help|-h|'-?') usage && exit 0 ;;
		--test|-t) tests+=( "$1" ) && shift ;;
		--) break ;;
		*)
			{
				echo "error: unknown flag: $flag"
				usage
			} >&2
			exit 1
			;;
	esac
done

# load config lists
# contains:
#   imageIncludeTests
#   globalExcludeTests
#   globalIncludeTests
. "$dir"/.config.sh

for image in "$@"; do
	noNamespace="${image##*/}"
	repo="${noNamespace%:*}"
	tagVar="${noNamespace#*:}"
	#version="${tagVar%-*}"
	variant="${tagVar##*-}"
	
	# TODO tests
	echo 'full:'$image 'repo:'$repo 'variant:'$variant
done
