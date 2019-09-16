#!/bin/bash
set -e
PS4='+\t '

# make sure we can GTFO
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# so we can have fancy stuff like !(pattern)
shopt -s extglob

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

library="$dir/../library"
src="$dir/src"
logs="$dir/logs"
namespaces='_'
docker='docker'
maxBgJobs=20
defaultSleepTime=2

library="$(readlink -f "$library")"
src="$(readlink -f "$src")"
logs="$(readlink -f "$logs")"

self="$(basename "$0")"
declare -a danglingImages=()

check_image_type() {
	local repo="$1"
	if [[ $repo == *"golang" ]]; then
		echo '-golang'
	fi
	if [[ $repo == *"python" ]]; then
		echo '-python'
	fi
	if [[ $repo == *"node" ]]; then
		echo '-node'
	fi
	if [[ $repo == *"openjdk" ]]; then
		echo '-openjdk'
	fi
	if [[ $repo == *"dotnet" ]]; then
		echo '-dotnet'
	fi
}

get_image_type() {
	local repo=$1
	case "$repo" in
	*"alpine"*)
		imageType='-alpine'
		imageType+=$(check_image_type $repo)
	;;
	*"fedora"*)
		imageType='-fedora'
		imageType+=$(check_image_type $repo)
	;;
	*"ubuntu"*)
		imageType='-ubuntu'
		imageType+=$(check_image_type $repo)
	;;
	*)
		imageType='-debian'
		imageType+=$(check_image_type $repo)
	;;
	esac
}

check_bg_jobs() {
	while [ $(jobs -rp | wc -l) -gt "$maxBgJobs" ]; do
		echo "Current background jobs maxed out, wait for a job to finish!"
		sleep $defaultSleepTime
	done
}

push_in_background() {
	local image=$1

	if ! "$docker" push "$image" &>> "$thisLog" < /dev/null; then
		echo >&2 "- $image failed to push; see $thisLog"
		didFail=1
	fi

	remove_image "$image"
}

push_image() {
	for namespace in $namespaces; do
		if [ "$namespace" = '_' ]; then
			# can't "docker push debian"; skip this namespace
			continue
		fi

		firstTag="${repoTag#*:}"

		if [ "$doPush" ]; then
			for aliasTag in $aliasTags; do
				repoTag="$repo:$aliasTag"
				tag="${repoTag#*:}"

				"$docker" tag "$repo:$firstTag" "$namespace/$repoTag"
				echo "Pushing $namespace/$repoTag..."
				check_bg_jobs
				push_in_background "$namespace/$repoTag" &
				if [[ $repo == *"debian"* ]]; then
					echo "Pushing $namespace/${repoTag/-debian/}..."
					"$docker" tag "$repo:$firstTag" "$namespace/${repoTag/-debian/}"
					check_bg_jobs
					push_in_background "$namespace/${repoTag/-debian/}" &
				fi

				if [ "$aliases" ]; then
					for alias in $aliases; do
						"$docker" tag "$repo:$firstTag" "$namespace/$alias$imageType:$tag"
						echo "Pushing alias: $namespace/$alias$imageType:$tag..."
						check_bg_jobs
						push_in_background "$namespace/$alias$imageType:$tag" &
						if [[ $repo == *"debian"* ]]; then
							"$docker" tag "$repo:$firstTag" "$namespace/$alias${imageType/-debian/}:$tag"
							echo "Pushing $namespace/$alias${imageType/-debian/}:$tag..."
							check_bg_jobs
							push_in_background "$namespace/$alias${imageType/-debian/}:$tag" &
						fi
						# Clean up pushed aliases
						#remove_image "$namespace/$alias$imageType:$tag"
						#remove_image "$namespace/$alias${imageType/-debian/}:$tag"
					done
				fi
				#remove_image "$namespace/${repoTag/-debian/}"
				#remove_image "$namespace/$repoTag"
			done
			# Clean up
			danglingImages+=("$repo:$firstTag")
			#remove_image "$repo:$firstTag"
		else
			echo "$docker push" "$namespace/$repoTag"
		fi
	done
}

remove_image() {
	retries=0
	echo "Removing $1"
	while [ "$retries" -lt 3 ]; do
		let retries=retries+1
		echo "Retrying remove $1"
		if "$docker" rmi -f "$1" ;then
			break	
		fi
	done
}

usage() {
	cat <<EOUSAGE

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
  --alias="$alias"
                     Specify alias for Docker images.

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
opts="$(getopt -o 'h?' --long 'all,docker:,help,library:,logs:,namespaces:,no-build,no-clone,no-push,src:,alias:' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

doClone=1
doBuild=1
doPush=1
buildAll=
while true; do
	flag=$1
	shift
	case "$flag" in
		--all) buildAll=1 ;;
		--docker) docker="$1" && shift ;;
		--help|-h|'-?') usage && exit 0 ;;
		--library) library="$1" && shift ;;
		--logs) logs="$1" && shift ;;
		--namespaces) namespaces="$1" && shift ;;
		--alias) aliases+=" $1" && shift ;;
		--no-build) doBuild= ;;
		--no-clone) doClone= ;;
		--no-push) doPush= ;;
		--src) src="$1" && shift ;;
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

# which subcommand
subcommand="$1"
case "$subcommand" in
	build|push|list)
		shift
		;;
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
	repos=( "$library"/!(MAINTAINERS) )
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
declare -A repoAliasList=()

logDir="$logs/$subcommand-$(date +'%Y-%m-%d--%H-%M-%S')"
mkdir -p "$logDir"

latestLogDir="$logs/latest" # this gets shiny symlinks to the latest buildlog for each repo we've seen since the creation of the logs dir
mkdir -p "$latestLogDir"

didFail=

# gather all the `repo:tag` combos to build
for repoTag in "${repos[@]}"; do
	repo="${repoTag%%:*}"
	get_image_type $repo
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
		
		repoFile="$(readlink -f "$repoFile")"
		echo "$repoTag ($repoFile)" >> "$logDir/repos.txt"
		
		cmd=( cat "$repoFile" )
	fi
	
	if [ "${repoGitRepo[$repoTag]}" ]; then
		queue+=( "$repoTag" )
		continue
	fi
	
	# parse the repo library file
	IFS=$'\n'
	repoTagLines=( $("${cmd[@]}" | grep -vE '^#|^\s*$') )
	unset IFS
	
	tags=()
	for line in "${repoTagLines[@]}"; do
		tag="$(echo "$line" | jq -r '.tag')"
		repoDir="$(echo "$line" | jq -r '.repoDir')"
		aliasTags="$(echo "$line" | jq -r '.alias')"
		
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
		
		if [ "$subcommand" == 'build' ]; then
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
					if ! (
						cd "$gitRepo"
						git rev-parse --verify "${gitRef}^{commit}" &> /dev/null
					); then
						echo "Fetching $repo ($gitUrl) ..."
						(
							cd "$gitRepo"
							git fetch -q --all
							git fetch -q --tags
						)
					fi
				fi
				
				# disable any automatic garbage collection too, just to help make sure we keep our dangling commit objects
				( cd "$gitRepo" && git config gc.auto 0 )
			fi
		fi
		
		repoGitRepo[$repo:$tag]="$gitRepo"
		repoGitRef[$repo:$tag]="$gitRef"
		repoGitDir[$repo:$tag]="$gitDir"
		repoAliasList[$repo:$tag]="$aliasTags"
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
	aliasTags="${repoAliasList[$repoTag]}"
	shift
	if [ -z "$gitRepo" ]; then
		echo >&2 'Unknown repo:tag:' "$repoTag"
		didFail=1
		continue
	fi
	
	thisLog="$logDir/$subcommand-$repoTag.log"
	touch "$thisLog"
	ln -sf "$thisLog" "$latestLogDir/$(basename "$thisLog")"
	
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
				if ! (
					set -x
					cd "$gitRepo"
					git reset -q HEAD
					git checkout -q -- .
					git clean -dfxq
					git checkout -q "$gitRef" --
					cd "$gitRepo/$gitDir"
					"$dir/git-set-mtimes"
				) &>> "$thisLog"; then
					echo "- failed 'git checkout'; see $thisLog"
					didFail=1
					continue
				fi
				
				if ! (
					set -x
					"$docker" pull "balenalib/$repoTag"
					"$docker" build --pull -t "$repoTag" "$gitRepo/$gitDir"
				) &>> "$thisLog"; then
					echo "- failed 'docker build'; see $thisLog"
					didFail=1
					continue
				fi
				push_image
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
			push_image
			;;
	esac
done

wait

#Remove all dangling images
for image in ${danglingImages[*]}; do
    remove_image "$image"
done

# Clean up all the Dockerfiles after building. This will free up hundreds of MB of space on the build server.
if [ -d "$gitRepo" ]; then
	rm -rf "$gitRepo"
fi

[ -z "$didFail" ]
