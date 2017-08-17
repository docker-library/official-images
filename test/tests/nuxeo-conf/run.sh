#!/bin/bash
set -eo pipefail

image="$1"

export NUXEO_DEV_MODE='true'
export NUXEO_AUTOMATION_TRACE='true'

docker run --rm -i \
	-e NUXEO_DEV_MODE \
	-e NUXEO_AUTOMATION_TRACE \
	"$image" \
	nuxeoctl showconf | grep "^org.nuxeo.[automation|dev]" | sort
