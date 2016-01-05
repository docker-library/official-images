#!/bin/sh
set -e

# list taken from https://rubygems.org/stats
for gem in \
	thor \
	rake \
	rails \
	rack \
	activesupport \
	activerecord \
	actionpack \
	json \
	actionmailer \
	activeresource
	do

	gem install "$gem"
done
