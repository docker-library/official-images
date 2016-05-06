#!/bin/bash
set -e

# make sure we can GTFO
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

library="$(dirname "$dir")/library"
src="$dir/src"
logs="$dir/logs"
namespaces='_'
docker='docker'
retries='4'

self="$(basename "$0")"

usage() {
	cat <<-EOUSAGE
		
		usage: $self [build|push|list] [options] [repo[:tag] ...]
		   ie: $self build --all
		       $self push debian ubuntu:12.04
		       $self list --namespaces='_' debian:7 hello-world
		
		This script processes the specified Docker images using the corresponding
		repository manifest files.
		
		common options:
		  --all              Build all repositories specified in library
		  --docker="$docker"
		                     Use a custom Docker binary
		  --retries="$retries"
		                     How many times to try again if the build/push fails before
		                     considering it a lost cause (always attempts a minimum of
		                     one time, but maximum of one plus this number)
		  --help, -h, -?     Print this help message
		  --library="$library"
		                     Where to find repository manifest files
		  --logs="$logs"
		                     Where to store the build logs
		  --namespaces="$namespaces"
		                     Space separated list of image namespaces to act upon
		                     
		                     Note that "_" is a special case here for the unprefixed
		                     namespace (ie, "debian" vs "library/debian"), and as such
		                     will be implicitly ignored by the "push" subcommand
		                     
		                     Also note that "build" will always tag to the unprefixed
		                     namespace because it is necessary to do so for dependent
		                     images to use FROM correctly (think "onbuild" variants that
		                     are "FROM base-image:some-version")
		  --uniq
		                     Only process the first tag of identical images
		                     This is not recommended for build or push
		                     i.e. process python:2.7, but not python:2
		
		build options:
		  --no-build         Don't build, print what would build
		  --no-clone         Don't pull/clone Git repositories
		  --src="$src"
		                     Where to store cloned Git repositories (GOPATH style)
		
		push options:
		  --no-push          Don't push, print what would push
		
	EOUSAGE
}

# arg handling
opts="$(getopt -o 'h?' --long 'all,docker:,help,library:,logs:,namespaces:,no-build,no-clone,no-push,retries:,src:,uniq' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

doClone=1
doBuild=1
doPush=1
buildAll=
onlyUniq=
while true; do
	flag="$1"
	shift
	case "$flag" in
		--all) buildAll=1 ;;
		--docker) docker="$1" && shift ;;
		--help|-h|'-?') usage && exit 0 ;;
		--library) library="$1" && shift ;;
		--logs) logs="$1" && shift ;;
		--namespaces) namespaces="$1" && shift ;;
		--no-build) doBuild= ;;
		--no-clone) doClone= ;;
		--no-push) doPush= ;;
		--retries) retries="$1" && (( retries++ )) && shift ;;
		--src) src="$1" && shift ;;
		--uniq) onlyUniq=1 ;;
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

if [ ! -d "$library" ]; then
	echo >&2 "error: library directory '$library' does not exist"
	exit 1
fi
library="$(readlink -f "$library")"
mkdir -p "$src" "$logs"
src="$(readlink -f "$src")"
logs="$(readlink -f "$logs")"

# which subcommand
subcommand="$1"
shift || { usage >&2 && exit 1; }
case "$subcommand" in
	build|push|list) ;;
	*)
		{
			echo "error: unknown subcommand: $1"
			usage
		} >&2
		exit 1
		;;
esac

repos=()
if [ "$buildAll" ]; then
	repos=( "$library"/* )
fi
repos+=( "$@" )

repos=( "${repos[@]%/}" )

if [ "${#repos[@]}" -eq 0 ]; then
	{
		echo 'error: no repos specified'
		usage
	} >&2
	exit 1
fi

# globals for handling the repo queue and repo info parsed from library
queue=()
declare -A repoGitRepo=()
declare -A repoGitRef=()
declare -A repoGitDir=()
declare -A repoUniq=()

logDir="$logs/$subcommand-$(date +'%Y-%m-%d--%H-%M-%S')"
mkdir -p "$logDir"

latestLogDir="$logs/latest" # this gets shiny symlinks to the latest buildlog for each repo we've seen since the creation of the logs dir
mkdir -p "$latestLogDir"

didFail=

# gather all the `repo:tag` combos to build
for repoTag in "${repos[@]}"; do
	repo="${repoTag%%:*}"
	tag="${repoTag#*:}"
	[ "$repo" != "$tag" ] || tag=
	
	if [ "$repo" = 'http' -o "$repo" = 'https' ] && [[ "$tag" == //* ]]; then
		# IT'S A URL!
		repoUrl="$repo:${tag%:*}"
		repo="$(basename "$repoUrl")"
		if [ "${tag##*:}" != "$tag" ]; then
			tag="${tag##*:}"
		else
			tag=
		fi
		repoTag="${repo}${tag:+:$tag}"
		
		echo "$repoTag ($repoUrl)" >> "$logDir/repos.txt"
		
		cmd=( curl -sSL --compressed "$repoUrl" )
	else
		if [ -f "$repo" ]; then
			repoFile="$repo"
			repo="$(basename "$repoFile")"
			repoTag="${repo}${tag:+:$tag}"
		else
			repoFile="$library/$repo"
		fi
		
		if [ ! -f "$repoFile" ]; then
			echo >&2 "error: '$repoFile' does not exist!"
			didFail=1
			continue
		fi
		
		repoFile="$(readlink -f "$repoFile")"
		echo "$repoTag ($repoFile)" >> "$logDir/repos.txt"
		
		cmd=( cat "$repoFile" )
	fi
	
	if [ "${repoGitRepo[$repoTag]}" ]; then
		if [ "$onlyUniq" ]; then
			uniqLine="${repoGitRepo[$repoTag]}@${repoGitRef[$repoTag]} ${repoGitDir[$repoTag]}"
			if [ -z "${repoUniq[$uniqLine]}" ]; then
				queue+=( "$repoTag" )
				repoUniq[$uniqLine]=$repoTag
			fi
		else
			queue+=( "$repoTag" )
		fi
		continue
	fi
	
	if ! manifest="$("${cmd[@]}")"; then
		echo >&2 "error: failed to fetch $repoTag (${cmd[*]})"
		exit 1
	fi
	
	# parse the repo manifest file
	IFS=$'\n'
	repoTagLines=( $(echo "$manifest" | grep -vE '^#|^\s*$') )
	unset IFS
	
	tags=()
	for line in "${repoTagLines[@]}"; do
		tag="$(echo "$line" | awk -F ': +' '{ print $1 }')"
		for parsedRepoTag in "${tags[@]}"; do
			if [ "$repo:$tag" = "$parsedRepoTag" ]; then
				echo >&2 "error: tag '$tag' is duplicated in '${cmd[@]}'"
				exit 1
			fi
		done
		
		repoDir="$(echo "$line" | awk -F ': +' '{ print $2 }')"
		
		gitUrl="${repoDir%%@*}"
		commitDir="${repoDir#*@}"
		gitRef="${commitDir%% *}"
		gitDir="${commitDir#* }"
		if [ "$gitDir" = "$commitDir" ]; then
			gitDir=
		fi
		
		gitRepo="${gitUrl#*://}"
		gitRepo="${gitRepo%/}"
		gitRepo="${gitRepo%.git}"
		gitRepo="${gitRepo%/}"
		gitRepo="$src/$gitRepo"
		
		if [ "$subcommand" = 'build' ]; then
			if [ -z "$doClone" ]; then
				if [ "$doBuild" -a ! -d "$gitRepo" ]; then
					echo >&2 "error: directory not found: $gitRepo"
					exit 1
				fi
			else
				if [ ! -d "$gitRepo" ]; then
					mkdir -p "$(dirname "$gitRepo")"
					echo "Cloning $repo ($gitUrl) ..."
					git clone -q "$gitUrl" "$gitRepo"
				else
					# if we don't have the "ref" specified, "git fetch" in the hopes that we get it
					if ! ( cd "$gitRepo" && git rev-parse --verify "${gitRef}^{commit}" &> /dev/null ); then
						echo "Fetching $repo ($gitUrl) ..."
						( cd "$gitRepo" && git fetch -q --all && git fetch -q --tags )
					fi
				fi
				
				# disable any automatic garbage collection too, just to help make sure we keep our dangling commit objects
				( cd "$gitRepo" && git config gc.auto 0 )
			fi
		fi
		
		repoGitRepo[$repo:$tag]="$gitRepo"
		repoGitRef[$repo:$tag]="$gitRef"
		repoGitDir[$repo:$tag]="$gitDir"
		tags+=( "$repo:$tag" )
	done
	
	if [ "$repo" != "$repoTag" ]; then
		tags=( "$repoTag" )
	fi
	
	if [ "$onlyUniq" ]; then
		for rt in "${tags[@]}"; do
			uniqLine="${repoGitRepo[$rt]}@${repoGitRef[$rt]} ${repoGitDir[$rt]}"
			if [ -z "${repoUniq[$uniqLine]}" ]; then
				queue+=( "$rt" )
				repoUniq[$uniqLine]=$rt
			fi
		done
	else
		# add all tags we just parsed
		queue+=( "${tags[@]}" )
	fi
done

# usage: gitCheckout "$gitRepo" "$gitRef" "$gitDir"
gitCheckout() {
	[ "$1" -a "$2" ] || return 1 # "$3" is allowed to be the empty string
	(
		set -x
		cd "$1"
		git reset -q HEAD
		git checkout -q -- .
		git clean -dfxq
		git checkout -q "$2" --
		cd "$1/$3"
		"$dir/git-set-mtimes"
	)
	return 0
}

set -- "${queue[@]}"
while [ "$#" -gt 0 ]; do
	repoTag="$1"
	gitRepo="${repoGitRepo[$repoTag]}"
	gitRef="${repoGitRef[$repoTag]}"
	gitDir="${repoGitDir[$repoTag]}"
	shift
	if [ -z "$gitRepo" ]; then
		echo >&2 'Unknown repo:tag:' "$repoTag"
		didFail=1
		continue
	fi
	
	thisLog="$logDir/$subcommand-$repoTag.log"
	touch "$thisLog"
	thisLogSymlink="$latestLogDir/$(basename "$thisLog")"
	ln -sf "$thisLog" "$thisLogSymlink"
	
	case "$subcommand" in
		build)
			echo "Processing $repoTag ..."
			
			if ! ( cd "$gitRepo" && git rev-parse --verify "${gitRef}^{commit}" &> /dev/null ); then
				echo "- failed; invalid ref: $gitRef"
				didFail=1
				continue
			fi
			
			dockerfilePath="$gitDir/Dockerfile"
			dockerfilePath="${dockerfilePath#/}" # strip leading "/" (for when gitDir is '') because "git show" doesn't like it
			
			if ! dockerfile="$(cd "$gitRepo" && git show "$gitRef":"$dockerfilePath")"; then
				echo "- failed; missing '$dockerfilePath' at '$gitRef' ?"
				didFail=1
				continue
			fi
			
			IFS=$'\n'
			froms=( $(echo "$dockerfile" | awk 'toupper($1) == "FROM" { print $2 ~ /:/ ? $2 : $2":latest" }') )
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
				if ! gitCheckout "$gitRepo" "$gitRef" "$gitDir" &>> "$thisLog"; then
					echo "- failed 'git checkout'; see $thisLog"
					didFail=1
					continue
				fi
				
				tries="$retries"
				while ! ( set -x && "$docker" build -t "$repoTag" "$gitRepo/$gitDir" ) &>> "$thisLog"; do
					(( tries-- )) || true
					if [ $tries -le 0 ]; then
						echo >&2 "- failed 'docker build'; see $thisLog"
						didFail=1
						continue 2
					fi
				done
				
				for namespace in $namespaces; do
					if [ "$namespace" = '_' ]; then
						# images FROM other images is explicitly supported
						continue
					fi
					if ! ( set -x && "$docker" tag -f "$repoTag" "$namespace/$repoTag" ) &>> "$thisLog"; then
						echo "- failed 'docker tag'; see $thisLog"
						didFail=1
						continue
					fi
				done
			fi
			;;
		list)
			for namespace in $namespaces; do
				if [ "$namespace" = '_' ]; then
					echo "$repoTag"
				else
					echo "$namespace/$repoTag"
				fi
			done
			;;
		push)
			for namespace in $namespaces; do
				if [ "$namespace" = '_' ]; then
					# can't "docker push debian"; skip this namespace
					continue
				fi
				if [ "$doPush" ]; then
					echo "Pushing $namespace/$repoTag..."
					tries="$retries"
					while ! ( set -x && "$docker" push "$namespace/$repoTag" < /dev/null ) &>> "$thisLog"; do
						(( tries-- )) || true
						if [ $tries -le 0 ]; then
							echo >&2 "- $namespace/$repoTag failed to push; see $thisLog"
							continue 2
						fi
					done
				else
					echo "$docker push" "$namespace/$repoTag"
				fi
			done
			;;
	esac
	
	if [ ! -s "$thisLog" ]; then
		rm "$thisLog" "$thisLogSymlink"
	fi
done

[ -z "$didFail" ]
