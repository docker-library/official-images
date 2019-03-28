#!/bin/bash
set -e

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

( cd "$dir/go" && go build -o bin/bashbrew -mod vendor bashbrew/src/bashbrew > /dev/null )

exec "$dir/go/bin/bashbrew" "$@"
