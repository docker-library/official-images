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
. "$dir/config.sh"

for dockerImage in "$@"; do
	echo "testing $dockerImage"
	
	if ! docker inspect "$dockerImage" &> /dev/null; then
		echo $'\timage does not exist!'
		continue
	fi
	
	noNamespace="${dockerImage##*/}"
	repo="${noNamespace%:*}"
	tagVar="${noNamespace#*:}"
	#version="${tagVar%-*}"
	variant="${tagVar##*-}"
	
	testRepo=$repo
	[ -z "${testAlias[$repo]}" ] || testRepo="${testAlias[$repo]}"
	
	# TODO use the argTests as the definitive list of available tests
	tests=( "${globalTests[@]}" ${imageTests[$testRepo]} ${imageTests[$testRepo:$variant]} )
	
	if [ "$testRepo" != "$repo" ]; then
		tests+=( ${imageTests[$repo]} ${imageTests[$repo:$variant]} )
	fi
	
	failures=0
	currentTest=0
	totalTest="${#tests[@]}"
	for t in "${tests[@]}"; do
		(( currentTest+=1 ))
		echo -ne "\t'$t' [$currentTest/$totalTest]..."
		
		if [ ! -z "${globalExcludeTests[${testRepo}_$t]}" -o ! -z "${globalExcludeTests[${testRepo}:${variant}_$t]}" -o ! -z "${globalExcludeTests[${repo}_$t]}" -o ! -z "${globalExcludeTests[${repo}:${variant}_$t]}" ]; then
			echo 'skipping'
			continue
		fi
		
		# run test against dockerImage here
		# find the script for the test
		scriptDir="$dir/tests/$t"
		if [ -d "$scriptDir" ]; then
			script="$scriptDir/run.sh"
			if [ -x "$script" -a ! -d "$script" ]; then
				# TODO dryRun logic
				if output="$("$script" $dockerImage)"; then
					if [ -f "$scriptDir/expected-std-out.txt" ] && ! d="$(echo "$output" | diff -u "$scriptDir/expected-std-out.txt" - 2>/dev/null)"; then
						echo 'failed; unexpected output:'
						echo "$d"
					else
						echo 'passed'
					fi
				else
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
