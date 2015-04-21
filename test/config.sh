#!/bin/bash
set -e

globalTests=(
	utc
	cve-2014--shellshock
)

declare -A testAlias=(
	[iojs]='node'
	[jruby]='ruby'
	[pypy]='python'

	[ubuntu]='debian'
	[ubuntu-debootstrap]='debian'

	[mariadb]='mysql'
	[percona]='mysql'
)

declare -A imageTests=(
	[aerospike]='
	'
	[busybox]='
	'
	[celery]='
	'
	[clojure]='
	'
	[crate]='
	'
	[debian]='
		debian-apt-get
	'
	[django]='
	'
	[elasticsearch]='
	'
	[gcc]='
	'
	[golang]='
	'
	[haskell]='
		haskell-cabal
		haskell-ghci
		haskell-runhaskell
	'
	[hylang]='
		hylang-sh
	'
	[java]='
	'
	[julia]='
	'
	[memcached]='
	'
	[mongo]='
	'
	[mono]='
	'
	[mysql]='
		mysql-basics
	'
	[node]='
	'
	[percona]='
	'
	[perl]='
	'
	[php]='
		php-ext-install
	'
	[php:fpm]='
		php-fpm-hello-web
	'
	[postgres]='
	'
	[python]='
		python-hy
		python-imports
		python-pip-requests-ssl
		python-sqlite3
	'
	[rabbitmq]='
	'
	[r-base]='
	'
	[rails]='
	'
	[redis]='
	'
	[rethinkdb]='
	'
	[ruby]='
		ruby-standard-libs
		ruby-gems
		ruby-bundler
	'
	[tomcat]='
	'
	[wordpress]='
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
