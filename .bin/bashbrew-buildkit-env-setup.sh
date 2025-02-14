#!/usr/bin/env bash

# this file is intended to be sourced before invocations of "bashbrew build" which might invoke "docker buildx" / BuildKit ("Builder: buildkit")

_resolve_external_pins() {
	local -
	set -Eeuo pipefail

	local binDir oiDir
	binDir="$(dirname "$BASH_SOURCE")"
	oiDir="$(dirname "$binDir")"

	local image
	for image; do
		[ -n "$image" ]
		local wc
		wc="$(wc -l <<<"$image")"
		[ "$wc" -eq 1 ]

		local file digest
		file="$("$oiDir/.external-pins/file.sh" "$image")"
		digest="$(< "$file")"
		[ -n "$digest" ]
		image+="@$digest"

		echo "$image"
	done
}

_jq_setenv() {
	local env="$1"; shift
	local val="$1"; shift
	jq -c --arg env "$env" --arg val "$val" '.[$env] = $val'
}

_bashbrew_buildkit_env_setup() {
	local -
	set -Eeuo pipefail

	local binDir oiDir
	binDir="$(dirname "$BASH_SOURCE")"
	oiDir="$(dirname "$binDir")"

	local externalPins
	externalPins="$("$oiDir/.external-pins/list.sh")"

	local vars='{}'

	local dockerfileTag
	dockerfileTag="$(grep <<<"$externalPins" -m1 '^tianon/buildkit:')"
	dockerfileTag="$(_resolve_external_pins "$dockerfileTag")"
	vars="$(_jq_setenv <<<"$vars" BASHBREW_BUILDKIT_SYNTAX "$dockerfileTag")"

	case "${BASHBREW_ARCH:-}" in
		windows-amd64) ;; # https://github.com/microsoft/Windows-Containers/issues/34
		'') ;; # if BASHBREW_ARCH isn't set explicitly, we shouldn't do more here
		*)
			BASHBREW_BUILDKIT_IMAGE="$(grep <<<"$externalPins" -m1 '^tianon/buildkit:')"
			BASHBREW_BUILDKIT_IMAGE="$(_resolve_external_pins "$BASHBREW_BUILDKIT_IMAGE")"
			export BASHBREW_BUILDKIT_IMAGE

			local buildxBuilder
			buildxBuilder="$("$binDir/docker-buildx-ensure.sh")" # reminder: this script *requires* BASHBREW_ARCH (to avoid "accidental amd64" mistakes)
			vars="$(_jq_setenv <<<"$vars" BUILDX_BUILDER "$buildxBuilder")"

			local sbomGenerator
			# https://hub.docker.com/r/docker/scout-sbom-indexer/tags
			sbomGenerator="$(grep <<<"$externalPins" -m1 '^docker/scout-sbom-indexer:')"
			sbomGenerator="$(_resolve_external_pins "$sbomGenerator")"
			# https://github.com/moby/buildkit/pull/5372 - "EXTRA_SCANNERS" is an optional parameter to the Scout SBOM Indexer
			sbomGenerator+=',"EXTRA_SCANNERS=php-composer-lock,erlang-otp-application,lua-rock-cataloger,swipl-pack-cataloger,opam-cataloger"'
			vars="$(_jq_setenv <<<"$vars" BASHBREW_BUILDKIT_SBOM_GENERATOR "$sbomGenerator")"
			;;
	esac

	if [ -t 1 ]; then
		jq <<<"$vars"
	else
		cat <<<"$vars"
	fi
}
_bashbrew_buildkit_env_setup
