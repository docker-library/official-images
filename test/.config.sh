#!/bin/bash
set -e

globalTests=(
	utc
)

declare -A testAlias=(
	[pypy]='python'
)

declare -A imageTests=(
	[python]='
		python
	'
# example onbuild
#	[python:onbuild]='
#		py-onbuild
#	'
)

declare -A globalExcludeTests=(
	[hello-world_utc]=1
)
