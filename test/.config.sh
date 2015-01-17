#!/bin/bash
set -e

globalTests=(
	utc
)

declare -A testAlias=(
	[pypy]='python'
	[jruby]='ruby'
)

declare -A imageTests=(
	[python]='
		python
	'
	[ruby]='
		ruby
	'
# example onbuild
#	[python:onbuild]='
#		py-onbuild
#	'
)

declare -A globalExcludeTests=(
	[hello-world_utc]=1
)
