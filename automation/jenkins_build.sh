#!/bin/bash

usage() {
	cat <<EOUSAGE
This script processes the specified Docker images using the corresponding
repository manifest files.

push options:
  -p          Don't build, only push image(s) to registry
EOUSAGE
}

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
	fi
	# Push all images
	./bashbrew.sh push $LIBRARY --library=../library --namespaces=resin
else
	for tag in $TAGS; do
		if [ ! -z "$pushOnly" ]; then
			# Build specified images only
			./bashbrew.sh build $LIBRARY:$tag --library=../library --namespaces=resin
		fi
		# Push specified images
		./bashbrew.sh push $LIBRARY:$tag --library=../library --namespaces=resin
	done
fi	
