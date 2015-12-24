#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

NUXEO_TEST_SLEEP=5
NUXEO_TEST_TRIES=10

cname="nuxeo-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

get() {
	docker run --rm -i \
		--link "$cname":nuxeo \
		"$image" curl -fs \
		-H "Content-Type:application/json" \
		-u Administrator:Administrator \
		http://nuxeo:8080/nuxeo/api/v1/$1 
}

. "./../../retry.sh" --tries "$NUXEO_TEST_TRIES" \
	--sleep "$NUXEO_TEST_SLEEP" \
	"get default-domain/workspaces"

PATH1="default-domain/workspaces"

# First get a document by its path to get its id
DUID=$(get path/$PATH1 | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["uid"];')

# Then get the same document by its id
PATH2=$(get id/$DUID | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["path"];')

# Compare both path
[ "/$PATH1" == "$PATH2" ]
