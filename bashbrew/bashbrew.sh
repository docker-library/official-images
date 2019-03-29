#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(readlink -f "$BASH_SOURCE")"
dir="$(dirname "$dir")"

export GO111MODULE=on
(
	cd "$dir/go"
	go build -o bin/bashbrew -mod vendor bashbrew/src/bashbrew > /dev/null
)

exec "$dir/go/bin/bashbrew" "$@"
