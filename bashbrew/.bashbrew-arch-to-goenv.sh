#!/bin/sh
set -euo pipefail

# usage: (from within another script)
#   eval "$(./.bashbrew-arch-to-goenv.sh)"
# since we need those new environment variables in our other script

bashbrewArch="$1"; shift # "amd64", "arm32v5", "windows-amd64", etc.

os="${bashbrewArch%%-*}"
[ "$os" != "$bashbrewArch" ] || os='linux'
printf 'export GOOS="%s"\n' "$os"

arch="${bashbrewArch#${os}-}"
case "$arch" in
	arm32v*)
		printf 'export GOARCH="%s"\n' 'arm'
		printf 'export GOARM="%s"\n' "${arch#arm32v}"
		;;

	arm64v*)
		printf 'export GOARCH="%s"\n' 'arm64'
		# no GOARM for arm64 (yet?) -- https://github.com/golang/go/blob/1e72bf62183ea21b9affffd4450d44d994393899/src/cmd/internal/objabi/util.go#L40
		#printf 'export GOARM="%s"\n' "${arch#arm64v}"
		printf 'unset GOARM\n'
		;;

	i386)
		printf 'export GOARCH="%s"\n' '386'
		printf 'unset GOARM\n'
		;;

	*)
		printf 'export GOARCH="%s"\n' "$arch"
		printf 'unset GOARM\n'
		;;
esac
