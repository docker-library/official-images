#!/bin/sh
set -e

gems="$(ruby -e '
	# list taken from https://rubygems.org/stats
	gems = %w{
		bundler
		multi_json
		rake
		rack
		json
		mime-types
		activesupport
		thor
		i18n
		diff-lcs
	}
	# last updated 2017-11-15

	require "json"
	require "open-uri"

	# https://github.com/ruby/ruby/commit/05aac90a1bcfeb180f5e78ea8b00a4d1b04d5eed
	# https://bugs.ruby-lang.org/issues/15893
	# for Ruby 2.5+, we should use "URI.open", but for Ruby 2.4 we still need to use "open(...)" directly
	def openURI(uri)
		if Gem::Version.create(RUBY_VERSION) >= Gem::Version.create("2.5")
			URI.open(uri)
		else
			open(uri)
		end
	end

	for gem in gems
		# ruby 2.2.2+: rack activesupport
		# ruby 2.0+: mime-types
		# (jruby 1.7 is ruby 1.9)
		gemRubyVersion = JSON.load(openURI("https://rubygems.org/api/v1/versions/#{ gem }.json"))[0]["ruby_version"]
		if Gem::Dependency.new("", gemRubyVersion).match?("", RUBY_VERSION)
			puts gem
		else
			STDERR.puts "skipping #{ gem } due to required Ruby version: #{ gemRubyVersion } (vs #{ RUBY_VERSION })"
		end
	end
')"

for gem in $gems; do
	echo "$ gem install $gem"
	gem install "$gem"
done
