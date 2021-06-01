#!/bin/bash
set -eo pipefail

# not using '--entrypoint', since regular entrypoint sets up config
docker run -i --rm \
	-e PLONE_DEVELOP=src/eea.facetednavigation \
	-e PLONE_ADDONS=eea.facetednavigation \
	-e PLONE_ZCML=eea.facetednavigation-meta \
	-v /plone/instance/bin/develop \
	"$1" cat custom.cfg
