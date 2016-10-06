#!/bin/bash
set -eo pipefail

image="$1"

PLONE_TEST_SLEEP=3
PLONE_TEST_TRIES=5

cname="plone-container-$RANDOM-$RANDOM"
cid="$(docker run -d -e PLONE_DEVELOP=src/eea.facetednavigation -e PLONE_ADDONS=eea.facetednavigation -e PLONE_ZCML=eea.facetednavigation-meta --name "$cname" "$image" cat)"
trap "docker rm -vf $cid > /dev/null" EXIT

docker exec -it "$cname" cat custom.cfg
