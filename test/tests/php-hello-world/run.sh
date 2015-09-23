#!/bin/bash

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/var/www/html/hello-world'

docker run -i --rm -v "$dirTest":"$dirContainer" -w "$dirContainer" "$image" php index.php
