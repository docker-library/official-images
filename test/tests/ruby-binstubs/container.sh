#!/bin/sh
set -e

dir="$(mktemp -d)"
trap "rm -rf '$dir'" EXIT

cp Gemfile "$dir"

cd "$dir"

bundle install
bundle audit version
