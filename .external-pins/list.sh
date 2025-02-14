#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$BASH_SOURCE")"

find "$dir" -mindepth 2 -type f -printf '%P\n' | sed -e 's/___/:/' | sort

# assumptions which make the "___" -> ":" conversion ~safe (examples referencing "example.com/foo/bar:baz"):
#
#   1. we *always* specify a tag ("baz")
#   2. the domain ("example.com") cannot contain underscores
#   3. we do not pin to any registry with a non-443 port ("example.com:8443")
#   4. the repository ("foo/bar") can only contain singular or double underscores (never triple underscore), and only between alphanumerics (thus never right up next to ":")
#   5. we do *not* use the "g" regex modifier in our sed, which means only the first instance of triple underscore is replaced (in pure Bash, that's "${img/:/___}" or "${img/___/:}" depending on the conversion direction)
#
# see https://github.com/distribution/distribution/blob/411d6bcfd2580d7ebe6e346359fa16aceec109d5/reference/regexp.go
# (see also https://github.com/docker-library/perl-bashbrew/blob/6685582f7889ef4806f0544b93f10640c7608b1a/lib/Bashbrew/RemoteImageRef.pm#L9-L26 for a condensed version)
#
# see https://github.com/docker-library/official-images/issues/13608 for why we can't just use ":" as-is (even though Linux, macOS, and even Windows via MSYS / WSL2 don't have any issues with it)
