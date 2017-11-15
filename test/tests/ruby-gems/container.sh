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

	for gem in gems
		# ruby 2.2.2+: rack activesupport
		# ruby 2.0+: mime-types
		# (jruby 1.7 is ruby 1.9)
		gemRubyVersion = JSON.load(open("https://rubygems.org/api/v1/versions/#{ gem }.json"))[0]["ruby_version"]
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
