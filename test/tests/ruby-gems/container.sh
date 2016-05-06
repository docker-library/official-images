#!/bin/sh
set -e

# list taken from https://rubygems.org/stats
for gem in \
	rake \
	rack \
	json \
	activesupport \
	thor \
	rails \
	activerecord \
	actionpack \
	actionmailer \
	activeresource \
; do
	gem install "$gem"
done
