#!/bin/sh
set -e

# ruby 2.2.2+: rack activesupport
# ruby 2.0+: mime-types
# (jruby 1.7 is ruby 1.9)
extras="$(ruby -e '
	rubyVersion = Gem::Version.new(RUBY_VERSION)
	puts (
		(
			rubyVersion >= Gem::Version.new("2.2.2") ? [
				"rack",
				"activesupport",
			] : []
		) + (
			rubyVersion >= Gem::Version.new("2.0") ? [
				"mime-types",
			] : []
		)
	).join(" ")
')"

# list taken from https://rubygems.org/stats
for gem in \
	$extras \
	rake \
	multi_json \
	bundler \
	json \
	thor \
	i18n \
	builder \
; do
	gem install "$gem"
done
