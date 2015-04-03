#!/bin/bash
set -e

docker images -q 'librarytest/*' | xargs docker rmi -f
