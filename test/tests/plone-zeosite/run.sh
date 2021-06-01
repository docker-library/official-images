#!/bin/bash
set -eo pipefail

# not using '--entrypoint', since regular entrypoint sets up config
docker run -i --rm \
    -e PLONE_DEVELOP=src/eea.facetednavigation \
	-e PLONE_ADDONS=eea.facetednavigation \
	-e PLONE_ZCML=eea.facetednavigation-meta \
	-e PLONE_VERSIONS="eea.facetednavigation=13.7 plone.restapi=6.13.0" \
	-e PLONE_SITE="plone" \
	-e PLONE_PROFILES="eea.facetednavigation:universal" \
	-e ZEO_ADDRESS="zeo:8080" \
	-v /plone/instance/bin/develop \
	"$1" cat custom.cfg
