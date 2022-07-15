#!/usr/bin/env bash

globalTests+=(
	utc
	no-hard-coded-passwords
	override-cmd
)

# for "explicit" images, only run tests that are explicitly specified for that image/variant
explicitTests+=(
	[:onbuild]=1
)
imageTests[:onbuild]+='
	override-cmd
'

testAlias+=(
	[amazoncorretto]='openjdk'
	[adoptopenjdk]='openjdk'
	[eclipse-temurin]='openjdk'
	[sapmachine]='openjdk'
	[ibm-semeru-runtimes]='openjdk'

	[jruby]='ruby'
	[pypy]='python'

	[ubuntu]='debian'

	[mariadb]='mysql'
	[percona]='mysql'
	[percona:psmdb]='mongo'
)

imageTests+=(
	[aerospike]='
	'
	[busybox]='
	'
	[cassandra]='
		cassandra-basics
	'
	[clojure]='
	'
	[crate]='
	'
	[composer]='
		composer
	'
	[convertigo]='
		convertigo-hello-world
	'
	[dart]='
		dart-hello-world
	'
	[debian]='
		debian-apt-get
	'
	[docker:dind]='
		docker-dind
		docker-registry-push-pull
	'
	[eclipse-mosquitto]='
		eclipse-mosquitto-basics
	'
	[elixir]='
		elixir-hello-world
	'
	[erlang]='
		erlang-hello-world
	'
	[gcc]='
		gcc-c-hello-world
		gcc-cpp-hello-world
		golang-hello-world
	'
	[ghost]='
		ghost-basics
	'
	[golang]='
		golang-hello-world
	'
	[haproxy]='
		haproxy-basics
	'
	[haskell]='
		haskell-cabal
		haskell-stack
		haskell-ghci
		haskell-runhaskell
	'
	[haxe]='
		haxe-hello-world
		haxe-haxelib-install
	'
	[hylang]='
		hylang-sh
		hylang-hello-world
	'
	[jetty]='
		jetty-hello-web
	'
	[julia]='
		julia-hello-world
		julia-downloads
	'
	[logstash]='
		logstash-basics
	'
	[memcached]='
		memcached-basics
	'
	[mongo]='
		mongo-basics
		mongo-auth-basics
		mongo-tls-basics
		mongo-tls-auth
	'
	[monica]='
		monica-cli
		monica-cli-mysql8
		monica-cli-mariadb10
	'
	[monica:apache]='
		monica-apache-run
	'
	[monica:fpm]='
		monica-fpm-run
	'
	[monica:fpm-alpine]='
		monica-fpm-run
	'
	[mongo-express]='
		mongo-express-run
	'
	[mono]='
	'
	[mysql]='
		mysql-basics
		mysql-initdb
		mysql-log-bin
	'
	[nextcloud]='
		nextcloud-cli
	'
	[nextcloud:apache]='
		nextcloud-apache-run
	'
	[nextcloud:fpm]='
		nextcloud-fpm-run
	'
	[node]='
		node-hello-world
	'
	[nuxeo]='
		nuxeo-conf
		nuxeo-basics
	'
	[openjdk]='
		java-hello-world
		java-uimanager-font
		java-ca-certificates
	'
	[open-liberty]='
		open-liberty-hello-world
	'
	[percona]='
		percona-tokudb
		percona-rocksdb
	'
	[perl]='
		perl-hello-world
		perl-cpanm
	'
	[php]='
		php-ext-install
		php-hello-world
		php-argon2
	'
	[php:apache]='
		php-apache-hello-web
	'
	[php:fpm]='
		php-fpm-hello-web
	'
	[plone]='
		plone-basics
		plone-addons
		plone-cors
		plone-versions
		plone-zeoclient
		plone-zeosite
	'
	[postgres]='
		postgres-basics
		postgres-initdb
	'
	[python]='
		python-hy
		python-imports
		python-no-pyc
		python-pip-requests-ssl
		python-sqlite3
		python-stack-size
	'
	[rabbitmq]='
		rabbitmq-basics
		rabbitmq-tls
	'
	[r-base]='
	'
	[rapidoid]='
		rapidoid-hello-world
		rapidoid-load-balancer
	'
	[redis]='
		redis-basics
		redis-basics-tls
		redis-basics-config
		redis-basics-persistent
	'
	[redmine]='
		redmine-basics
	'
	[registry]='
		docker-registry-push-pull
	'
	[rethinkdb]='
	'
	[ruby]='
		ruby-hello-world
		ruby-standard-libs
		ruby-gems
		ruby-bundler
		ruby-nonroot
		ruby-binstubs
		ruby-native-extension
	'
	[rust]='
		rust-hello-world
	'
	[silverpeas]='
		silverpeas-basics
	'
	[spiped]='
		spiped-basics
	'
	[swipl]='
		swipl-modules
	'
	[swift]='
		swift-hello-world
	'
	[tomcat]='
		tomcat-hello-world
	'
	[varnish]='
		varnish
	'
	[wordpress:apache]='
		wordpress-apache-run
	'
	[wordpress:fpm]='
		wordpress-fpm-run
	'
	[znc]='
		znc-basics
	'
	[zookeeper]='
		zookeeper-basics
	'
)

globalExcludeTests+=(
	# single-binary images
	[hello-world_no-hard-coded-passwords]=1
	[hello-world_utc]=1
	[nats-streaming_no-hard-coded-passwords]=1
	[nats-streaming_utc]=1
	[nats_no-hard-coded-passwords]=1
	[nats_utc]=1
	[traefik_no-hard-coded-passwords]=1
	[traefik_utc]=1

	# clearlinux has no /etc/passwd
	# https://github.com/docker-library/official-images/pull/1721#issuecomment-234128477
	[clearlinux_no-hard-coded-passwords]=1

	# alpine/slim/nanoserver openjdk images are headless and so can't do font stuff
	[openjdk:alpine_java-uimanager-font]=1
	[openjdk:slim_java-uimanager-font]=1
	[openjdk:nanoserver_java-uimanager-font]=1

	# the Swift slim images are not expected to be able to run the swift-hello-world test because it involves compiling Swift code. The slim images are for running an already built binary.
	# https://github.com/docker-library/official-images/pull/6302#issuecomment-512181863
	[swift:slim_swift-hello-world]=1

	# The new tag kernel-slim provides the bare minimum server image for users to build upon to create their application images.
	# https://github.com/docker-library/official-images/pull/8993#issuecomment-723328400
	[open-liberty:slim_open-liberty-hello-world]=1

	# no "native" dependencies
	[ruby:alpine_ruby-bundler]=1
	[ruby:alpine_ruby-gems]=1
	[ruby:slim_ruby-bundler]=1
	[ruby:slim_ruby-gems]=1

	# MySQL-assuming tests cannot be run on MongoDB-providing images
	[percona:psmdb_percona-tokudb]=1
	[percona:psmdb_percona-rocksdb]=1

	# windows!
	[:nanoserver_no-hard-coded-passwords]=1
	[:nanoserver_utc]=1
	[:windowsservercore_no-hard-coded-passwords]=1
	[:windowsservercore_utc]=1

	# https://github.com/docker-library/official-images/pull/2578#issuecomment-274889851
	[nats:nanoserver_override-cmd]=1
	[nats:windowsservercore_override-cmd]=1
	[nats-streaming:nanoserver_override-cmd]=1
	[nats-streaming:windowsservercore_override-cmd]=1

	# https://github.com/docker-library/official-images/pull/8329#issuecomment-656383836
	[traefik:windowsservercore_override-cmd]=1

	# TODO adjust MongoDB tests to use docker networks instead of links so they can work on Windows (and consider using PowerShell to generate appropriate certificates for TLS tests instead of openssl)
	[mongo:nanoserver_mongo-basics]=1
	[mongo:nanoserver_mongo-auth-basics]=1
	[mongo:nanoserver_mongo-tls-basics]=1
	[mongo:nanoserver_mongo-tls-auth]=1
	[mongo:windowsservercore_mongo-basics]=1
	[mongo:windowsservercore_mongo-auth-basics]=1
	[mongo:windowsservercore_mongo-tls-basics]=1
	[mongo:windowsservercore_mongo-tls-auth]=1
)
