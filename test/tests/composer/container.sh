#!/bin/sh

dir="$(mktemp -d)"

trap "rm -rf '$dir'" EXIT

cp composer.json "$dir"

cd "$dir"

composer --version
composer install
