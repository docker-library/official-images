#!/bin/bash
set -e

globalTests+=(
	utc
	cve-2014--shellshock
	no-hard-coded-passwords
	override-cmd
)

testAlias+=(
	[iojs]='node'
	[jruby]='ruby'
	[pypy]='python'

	[ubuntu]='debian'
	[ubuntu-debootstrap]='debian'

	[mariadb]='mysql'
	[percona]='mysql'
)

imageTests+=(
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
	[docker:dind]='
		docker-dind
	'
	[django]='
	'
	[elasticsearch]='
	'
	[gcc]='
		gcc-c-hello-world
	'
	[golang]='
		golang-hello-world
	'
	[haskell]='
		haskell-cabal
		haskell-ghci
		haskell-runhaskell
	'
	[hylang]='
		hylang-sh
		hylang-hello-world
	'
	[java]='
	'
	[jetty]='
		jetty-hello-web
	'
	[julia]='
		julia-hello-world
	'
	[memcached]='
	'
	[mongo]='
		mongo-basics
	'
	[mono]='
	'
	[mysql]='
		mysql-basics
		mysql-initdb
	'
	[node]='
		node-hello-world
	'
	[percona]='
	'
	[perl]='
		perl-hello-world
	'
	[php]='
		php-ext-install
		php-hello-world
	'
	[php:fpm]='
		php-fpm-hello-web
	'
	[postgres]='
		postgres-basics
		postgres-initdb
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
		ruby-hello-world
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

globalExcludeTests+=(
	# single-binary images
	[hello-world_utc]=1
	[swarm_utc]=1
	[nats_utc]=1

	[hello-world_no-hard-coded-passwords]=1
	[swarm_no-hard-coded-passwords]=1
	[nats_no-hard-coded-passwords]=1

	[hello-world_override-cmd]=1
	[swarm_override-cmd]=1
	[nats_override-cmd]=1

	# no "native" dependencies
	[ruby:slim_ruby-bundler]=1
	[ruby:slim_ruby-gems]=1
)

