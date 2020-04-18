#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"

# Use a client image with curl for testing
clientImage='buildpack-deps:buster-curl'

# Create an instance of the container-under-test
cid="$(docker run -d "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

_request() {
	local method="$1"
	shift

	local url="${1#/}"
	shift

	docker run --rm \
		--link "$cid":redmine \
		"$clientImage" \
		curl -fs -X"$method" "$@" "http://redmine:3000/$url"
}

# Make sure that Redmine is listening and ready
# (give it plenty of time, since it needs to do a lot of database migrations)
. "$dir/../../retry.sh" --tries 40 '_request GET / --output /dev/null'

# Check that / include the text "Redmine" somewhere
_request GET '/' |tac|tac| grep -q Redmine

# Check that /account/register include the text "Password" somewhere
_request GET '/account/register' |tac|tac| grep -q Password
