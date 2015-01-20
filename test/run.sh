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

argTests=()
dryRun=
while true; do
	flag=$1
	shift
	case "$flag" in
		--dry-run) dryRun=1 ;;
		--help|-h|'-?') usage && exit 0 ;;
		--test|-t) argTests+=( "$1" ) && shift ;;
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
#   globalTests
#   testAlias
#   imageTests
#   globalExcludeTests
. "$dir"/.config.sh

for dockerImage in "$@"; do
	echo "testing $dockerImage"
	
	noNamespace="${dockerImage##*/}"
	repo="${noNamespace%:*}"
	tagVar="${noNamespace#*:}"
	#version="${tagVar%-*}"
	variant="${tagVar##*-}"
	
	testRepo=$repo
	[ -z "${testAlias[$repo]}" ] || testRepo="${testAlias[$repo]}"
	
	# TODO use the argTests as the definitive list of available tests
	tests=( "${globalTests[@]}" ${imageTests[$testRepo]} ${imageTests[$testRepo:$variant]} )
	
	failures=0
	currentTest=1
	totalTest="${#tests[@]}"
	for t in "${tests[@]}"; do
		echo -ne "\t'$t' [$currentTest/$totalTest]..."
		(( currentTest+=1 ))
		
		if [ ! -z "${globalExcludeTests[${testRepo}_$t]}" -o ! -z "${globalExcludeTests[${testRepo}:${variant}_$t]}" ]; then
			echo 'skipping'
			continue
		fi
		
		# run test against dockerImage here
		# find the script for the test
		scriptDir=( "$dir/tests/$t" )
		if [ "${#scriptDir[@]}" -gt 1 ]; then
			echo >&2 "error: $t matches multiple files: ${scriptDir[*]}"
			continue
		fi
		if [ -d "$scriptDir" ]; then
			script="$scriptDir/run.sh"
			if [ -x "$script" -a ! -d "$script" ]; then
				# TODO dryRun logic
				if output="$("$script" $dockerImage)"; then
					echo 'passed'
				else
					# TODO somethin with output (maybe also catch stderr)
					echo 'failed'
				fi
			else
				# TODO warn scipt is not executable
				echo "skipping"
				echo >&2 "error: $script missing, not executable or is a directory"
				continue
			fi
		else
			echo "skipping"
			echo >&2 "error: $scriptDir is not a directory"
			continue
		fi
	done
done
