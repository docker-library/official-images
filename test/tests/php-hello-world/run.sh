#!/bin/bash

IMAGE="$1"
DIR="/var/www/html/hello-world"

docker run -it --rm -v $PWD:$DIR -w $DIR $IMAGE php index.php
