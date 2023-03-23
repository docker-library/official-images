#!/usr/bin/env bash
set -Eeuo pipefail

: "${BASHBREW_ARCH:?missing explicit BASHBREW_ARCH}"
: "${BASHBREW_BUILDKIT_IMAGE:?missing explicit BASHBREW_BUILDKIT_IMAGE (moby/buildkit:buildx-stable-1 ?)}"

builderName="bashbrew-$BASHBREW_ARCH"
container="buildx_buildkit_$builderName"

# make sure the buildx builder name is the only thing that we print to stdout (so this script's output can be captured and used to set BUILDX_BUILDER)
echo "$builderName"
exec >&2

if docker buildx inspect "$builderName" &> /dev/null; then
	if containerImage="$(docker container inspect --format '{{ .Config.Image }}' "$container" 2>/dev/null)" && [ "$containerImage" = "$BASHBREW_BUILDKIT_IMAGE" ]; then
		echo >&2
		echo >&2 "note: '$container' container already exists and is running the correct image ('$BASHBREW_BUILDKIT_IMAGE'); bailing instead of recreating the '$builderName' builder (to avoid unnecessary churn)"
		echo >&2
		exit 0
	fi

	docker buildx rm --keep-state "$builderName"
fi

platform="$(bashbrew cat --format '{{ ociPlatform arch }}' <(echo 'Maintainers: empty hack (@example)'))"

hubMirrors="$(docker info --format '{{ json .RegistryConfig.Mirrors }}' | jq -c '
	[ env.DOCKERHUB_PUBLIC_PROXY // empty, .[] ]
	| map(select(startswith("https://")) | ltrimstr("https://") | rtrimstr("/") | select(contains("/") | not))
	| reduce .[] as $item ( # "unique" but order-preserving (we want DOCKERHUB_PUBLIC_PROXY first followed by everything else set in the dockerd mirrors config without duplication)
		[];
		if index($item) then . else . + [ $item ] end
	)
')"

read -r -d '' buildkitdConfig <<-EOF || :
	# https://github.com/moby/buildkit/blob/v0.11.4/docs/buildkitd.toml.md

	[worker.oci]
		platforms = [ "$platform" ]
		gc = false # we want to do GC manually

	# this should be unused (for now?), but included for completeness/safety
	[worker.containerd]
		platforms = [ "$platform" ]
		namespace = "buildkit-$builderName"
		gc = false

	[registry."docker.io"]
		mirrors = $hubMirrors
EOF

# https://docs.docker.com/engine/reference/commandline/buildx_create/
docker buildx create \
	--name "$builderName" \
	--node "$builderName" \
	--config <(printf '%s' "$buildkitdConfig") \
	--platform "$platform" \
	--driver docker-container \
	--driver-opt image="$BASHBREW_BUILDKIT_IMAGE" \
	--bootstrap

# 👀
docker update --restart=always "$container"
