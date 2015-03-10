#!/bin/bash
set -e

globalTests=(
	utc
	cve-2014--shellshock
)

declare -A testAlias=(
	[jruby]='ruby'
	[pypy]='python'

	[mariadb]='mysql'
	[percona]='mysql'
)

declare -A imageTests=(
	[haskell]='
		haskell-cabal
		haskell-ghci
		haskell-runhaskell
	'
	[hylang]='
		hylang-sh
	'
	[mysql]='
		mysql-basics
	'
	[php]='
		php-ext-install
	'
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
	# single-binary images
	[hello-world_utc]=1
	[swarm_utc]=1

	# no "native" dependencies
	[ruby:slim_ruby-bundler]=1
	[ruby:slim_ruby-gems]=1
)
