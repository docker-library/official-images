#!/bin/bash
set -e

tz="$(docker run --rm --entrypoint date "$1" +%Z)"
tzE='UTC'
if [ "$tz" != "$tzE" ]; then
	echo >&2 "error: expected '$tzE', got '$tz'"
	exit 1
fi
