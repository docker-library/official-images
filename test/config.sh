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
		python-hy
		python-pip-requests-ssl
		python-sqlite3
		python-zlib
	'
	[ruby]='
		ruby-standard-libs
		ruby-gems
		ruby-bundler
	'
# example onbuild
#	[python:onbuild]='
#		py-onbuild
#	'
)

declare -A globalExcludeTests=(
	[hello-world_utc]=1
)
