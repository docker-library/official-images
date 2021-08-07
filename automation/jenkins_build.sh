#!/bin/bash

usage() {
	cat <<EOUSAGE
This script processes the specified Docker images using the corresponding
repository manifest files.

push options:
  -p			Don't build, only push image(s) to registry.
  -a			Specify image aliases.

EOUSAGE
}

# If the build fails, set 1 as exit code and store failed image.
is_success() {
	if [ $1 -ne 0 ]; then
		exitCode=1
		if [ -z "$TAGS" ]; then
			failedList+=($LIBRARY)
		else
			failedList+=($LIBRARY:$2)
		fi
	fi
}

exitCode=0
failedList=()
pushOnly=
aliases=
args=

# Args handling
while getopts ":pa"  opt; do
	case $opt in
		p)
			pushOnly=1
			;;
		a)
			shift
			aliases=$1 && shift
			;;
		\?)
			{
				echo "Invalid option: -$OPTARG"
				usage
			}>&2
			exit 1
      		;;
	esac
done

# parse platform
if [ ! -z "$PLATFORM" ]; then
	args+=" --platform=$PLATFORM"
fi

# parse aliases
if [ ! -z "$aliases" ]; then
	for alias in $aliases; do
		args+=" --alias=$alias"
	done
fi

# Jenkins build steps
cd bashbrew/
if [ -z "$TAGS" ]; then
	if [ -z "$pushOnly" ]; then
		# Build and push all images
		./bashbrew.sh build $LIBRARY --library=../library --namespaces=balenalib $args
		is_success $?
	else
		# Push all images
		./bashbrew.sh push $LIBRARY --library=../library --namespaces=balenalib $args
		is_success $?
	fi
else
	for tag in $TAGS; do
		if [ -z "$pushOnly" ]; then
			# Build specified images only
			./bashbrew.sh build $LIBRARY:$tag --library=../library --namespaces=balenalib $args
			is_success $? $tag
		else
			# Push specified images
			./bashbrew.sh push $LIBRARY:$tag --library=../library --namespaces=balenalib $args
			is_success $? $tag
		fi
	done
fi

# if the build is marked as failed, print failed images and tidy up everything
if [ $exitCode -eq 1 ]; then
	echo Failed images: ${failedList[@]}
	# we need to clean up all untagged images when builds fail.
	# First remove all stopped containers.
	docker rm -v $(docker ps --filter status=exited --filter "ancestor=$LIBRARY" -q)
	# Then clean up untagged images.
	docker rmi $(docker images --filter dangling=true -q)
fi
