#!/usr/bin/env sh
set -eu

dir="$(mktemp -d)"
trap "rm -rf '$dir'" EXIT

cp Gemfile "$dir"

cd "$dir"

bundle install

if bundle info bundler-compose; then
	bundle compose help > /dev/null
else
	bundle info bundler-audit
	bundle audit version
fi

bundle info brakeman
brakeman --version
