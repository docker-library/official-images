#!/bin/sh
set -e

gems="$(ruby -e '
	# list taken from https://rubygems.org/stats
	gems = %w{
		bundler
		aws-sdk-core
		i18n
		activesupport
		rack
		rake
		concurrent-ruby
		json
		tzinfo
		nokogiri
		diff-lcs
	}
	# last updated 2026-01-12
	# to try to get a wider coverage of common gems, this list skips the direct deps of aws-sdk-core
	# (aws-eventstream, aws-partitions, aws-sigv4, jmespath)
	# skip minitest, it has native deps (needs a compiler for c code, which will not work in jruby images)

	require "json"
	require "open-uri"

	# only install gems where the current ruby version is new enough for the gem
	for gem in gems
		# grabbing the first item might be checking ruby_version against a pre-release version of the gem
		# TODO also save version of the gem for the gem install? `gem install [GEM] -v [VERSION]`
		# TODO or skip pre-releases?
		gemRubyVersion = JSON.load(URI.open("https://rubygems.org/api/v1/versions/#{ gem }.json"))[0]["ruby_version"]

		# https://github.com/rubygems/rubygems.org/blob/d05f69e8e800acf1dd21bb6f8e5f174410f81a33/app/models/version.rb#L304
		# https://github.com/ruby/rubygems/blob/e7cb04353fc8fe85d359d34d9d467d17d33bdbd3/lib/rubygems/specification.rb#L148
		# https://github.com/ruby/rubygems/blob/e7cb04353fc8fe85d359d34d9d467d17d33bdbd3/lib/rubygems/requirement.rb#L259-L261
		gemRubyVersion = gemRubyVersion.split(", ")

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
