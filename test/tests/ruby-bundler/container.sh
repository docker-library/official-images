#!/bin/bash
set -e

dir="$(mktemp -d)"
trap "rm -rf '$dir'" EXIT

cp Gemfile "$dir"

# make sure that running "bundle" twice doesn't change Gemfile.lock the second time
cd "$dir"
bundle
cp Gemfile.lock{,.orig}
bundle
diff -u Gemfile.lock{.orig,} >&2
