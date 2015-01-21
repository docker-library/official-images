#!/bin/bash
set -e

# list taken from https://rubygems.org/stats
gems=(
	thor
	rake
	rails
	rack
	activesupport
	activerecord
	actionpack
	json
	actionmailer
	activeresource
)

for gem in "${gems[@]}"; do
	gem install "$gem"
done
