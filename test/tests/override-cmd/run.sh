#!/bin/bash

set -eo pipefail

image="$1"

# Test that we can override the CMD with echo
hello="world-$RANDOM-$RANDOM"
output="$(docker run --rm "$image" echo "Hello $hello")"
[ "$output" = "Hello $hello" ]
