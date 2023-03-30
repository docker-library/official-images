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
	dockerfileTag="$(grep <<<"$externalPins" -m1 '^docker/dockerfile:')"
	dockerfileTag="$(_resolve_external_pins "$dockerfileTag")"
	vars="$(_jq_setenv <<<"$vars" BASHBREW_BUILDKIT_SYNTAX "$dockerfileTag")"

	case "${BASHBREW_ARCH:-}" in
		nope) # amd64 | arm64v8) # TODO re-enable this once we figure out how to handle "docker build --tag X" + "FROM X" correctly all-local
			BASHBREW_BUILDKIT_IMAGE="$(grep <<<"$externalPins" -m1 '^moby/buildkit:')"
			BASHBREW_BUILDKIT_IMAGE="$(_resolve_external_pins "$BASHBREW_BUILDKIT_IMAGE")"
			export BASHBREW_BUILDKIT_IMAGE

			local buildxBuilder
			buildxBuilder="$("$binDir/docker-buildx-ensure.sh")" # reminder: this script *requires* BASHBREW_ARCH (to avoid "accidental amd64" mistakes)
			vars="$(_jq_setenv <<<"$vars" BUILDX_BUILDER "$buildxBuilder")"

			local sbomTag
			sbomTag="$(grep <<<"$externalPins" -m1 '^docker/buildkit-syft-scanner:')"
			sbomTag="$(_resolve_external_pins "$sbomTag")"
			vars="$(_jq_setenv <<<"$vars" BASHBREW_BUILDKIT_SBOM_GENERATOR "$sbomTag")"
			;;
	esac

	if [ -t 1 ]; then
		jq <<<"$vars"
	else
		cat <<<"$vars"
	fi
}
_bashbrew_buildkit_env_setup
