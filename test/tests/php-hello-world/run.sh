#!/bin/bash

IMAGE="$1"
DIR_TEST="$(dirname "$(readlink -f "$BASH_SOURCE")")"
DIR_CONTAINER="/var/www/html/hello-world"

docker run -it --rm -v $DIR_TEST:$DIR_CONTAINER -w $DIR_CONTAINER $IMAGE php index.php
