#!/bin/bash

usage() {
	cat <<EOUSAGE
This script processes the specified Docker images using the corresponding
repository manifest files.

push options:
  -p          Don't build, only push image(s) to registry
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

# Args handling
while getopts ":p" opt; do
  case $opt in
    p)
      	pushOnly=1
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

# Jenkins build steps
cd bashbrew/
if [ -z "$TAGS" ]; then
	if [ -z "$pushOnly" ]; then
		# Build all images
		./bashbrew.sh build $LIBRARY --library=../library --namespaces=resin
		is_success $?
	fi
	# Push all images
	./bashbrew.sh push $LIBRARY --library=../library --namespaces=resin
	is_success $?
else
	for tag in $TAGS; do
		if [ -z "$pushOnly" ]; then
			# Build specified images only
			./bashbrew.sh build $LIBRARY:$tag --library=../library --namespaces=resin
			is_success $? $tag
		fi
		# Push specified images
		./bashbrew.sh push $LIBRARY:$tag --library=../library --namespaces=resin
		is_success $? $tag
	done
fi

# if the build is marked as failed, print failed images
if [ $exitCode -eq 1 ]; then
	echo Failed images: ${failedList[@]}
	exit 1
fi	
