#!/bin/sh
set -e

dir="$(mktemp -d)"
trap "rm -rf '$dir'" EXIT

cp Gemfile "$dir"

cd "$dir"

gem install bundler -v "$1"
bundle install
bundle audit version
