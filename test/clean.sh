#!/bin/bash
set -e

docker images 'librarytest/*' | awk 'NR>1 { print $1":"$2 }' | xargs -r docker rmi
