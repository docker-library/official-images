#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

buildDepsImage="$image"
if ! docker run --rm --entrypoint sh "$image" -c 'command -v gcc' > /dev/null; then
	buildDepsImage="$("$dir/../image-name.sh" librarytest/ruby-native-extension "$image")"

	os="$(docker run --rm --entrypoint sh "$image" -c '. /etc/os-release && echo "$ID"')"
	case "$os" in
		alpine)
			"$dir/../docker-build.sh" "$dir" "$buildDepsImage" <<-EOD
				FROM $image
				RUN apk add --no-cache gcc make musl-dev
			EOD
			;;

		*) # must be Debian slim variants (no gcc but not Alpine)
			"$dir/../docker-build.sh" "$dir" "$buildDepsImage" <<-EOD
				FROM $image
				RUN set -eux; \
					apt-get update; \
					apt-get install -y --no-install-recommends gcc make libc6-dev; \
					rm -rf /var/lib/apt/lists/*
			EOD
			;;
	esac
fi

docker run --interactive --rm --entrypoint sh "$buildDepsImage" -eu <<-'EOSH'
	if command -v jruby > /dev/null; then
		platform='jruby'
	else
		platform='ruby'
	fi
	gem install bcrypt \
		--version 3.1.16 \
		--platform "$platform" \
		--silent
	ruby -e 'require "bcrypt"; print "it works\n"'
EOSH
