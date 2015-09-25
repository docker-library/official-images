#!/bin/bash
set -e

image="$1"
dirTest="$(dirname "$(readlink -f "$BASH_SOURCE")")"
dirContainer='/var/www/html/hello-world'

docker run --rm -v "$dirTest":"$dirContainer":ro -w "$dirContainer" "$image" php index.php
