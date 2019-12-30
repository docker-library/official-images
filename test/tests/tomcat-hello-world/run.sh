#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# since the "slim" tomcat variants don't have wget, we'll use buildpack-deps
clientImage='buildpack-deps:stretch-curl'

serverImage="$("$dir/../image-name.sh" librarytest/tomcat-hello-world "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
COPY dir/index.jsp \$CATALINA_HOME/webapps/ROOT/
EOD

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local url="${1#/}"
	shift

	docker run --rm --link "$cid":tomcat "$clientImage" \
		wget -q -O - "$@" "http://tomcat:8080/$url"
}

# Make sure that Tomcat is listening
. "$dir/../../retry.sh" '_request / &> /dev/null'

# Check that our simple servlet works
helloWorld="$(_request '/')"
[[ "$helloWorld" == *'Hello Docker World!'* ]]
