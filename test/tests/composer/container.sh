#!/bin/sh

dir="$(mktemp -d)"

trap "rm -rf '$dir'" EXIT

cp composer.json "$dir"

cd "$dir"

composer --version
composer install --no-interaction --no-progress --no-ansi --profile
