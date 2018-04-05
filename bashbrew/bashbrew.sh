#!/bin/bash
set -e
export PATH=$GOPATH/bin:$PATH

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

if ! command -v gb &> /dev/null; then
	( set -x && go get github.com/constabulary/gb/... )
fi

( cd "$dir/go" && gb build > /dev/null )

echo "$dir/go/bin/bashbrew "
exec "$dir/go/bin/bashbrew" "$@"
