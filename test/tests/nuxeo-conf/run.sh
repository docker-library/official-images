#!/bin/bash
set -eo pipefail

image="$1"

export NUXEO_DEV_MODE='true'
export NUXEO_AUTOMATION_TRACE='true'

# not using '--entrypoint nuxeoctl', since regular entrypoint does setup for nuxeoctl
docker run --rm -i \
	-e NUXEO_DEV_MODE \
	-e NUXEO_AUTOMATION_TRACE \
	"$image" \
	nuxeoctl showconf | grep "^org.nuxeo.[automation|dev]" | sort
