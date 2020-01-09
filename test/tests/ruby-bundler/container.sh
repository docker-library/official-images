#!/bin/sh
set -e

dir="$(mktemp -d)"
trap "rm -rf '$dir'" EXIT

cp Gemfile "$dir"

# make sure that running "bundle" twice doesn't change Gemfile.lock the second time
cd "$dir"
BUNDLE_FROZEN=0 bundle install
cp Gemfile.lock Gemfile.lock.orig
BUNDLE_FROZEN=1 bundle install
diff -u Gemfile.lock.orig Gemfile.lock >&2

if ruby -rbundler -e 'exit Gem::Version.new(Bundler::VERSION) >= Gem::Version.new("2.1") ? 0 : 1'; then
	BUNDLE_DEPLOYMENT=1 bundle install
else
	bundle install --deployment
fi
diff -u Gemfile.lock.orig Gemfile.lock >&2
