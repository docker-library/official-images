#!/usr/bin/env bash
set -Eeuo pipefail

# scans each image below with the "docker/scout-sbom-indexer" pin in this checkout (see ".bin/bashbrew-buildkit-env-setup.sh") and reports what it found
#
# usage: .github/workflows/test-sbom-indexer.sh [old-digest]
# - fails if a scan fails or an image is missing a package type it is meant to exercise
# - with an "old-digest" (a previous value of the pin), also scans with that and fails if the new indexer finds fewer unique packages (name, version, and type)
# - an "old-digest" that is the same as the pin has nothing to compare it to, so it is the same as not giving one

# image, then the package types (purl types) that must show up in its SBOM, and a comment about what it is for
# - pinned by digest so the test is repeatable (and so it can include old images)
# - the ones tagged "latest" were resolved on 2026-11-18
images=(
	'alpine:3.14@sha256:0f2d5c38dd7a4f4f733e688e3a6733cb5ab1ac6e3cb4603a5dd564e5bfb80eed apk' # apk, on an old release
	'debian:buster@sha256:58ce6f1271ae1c8a2006ff7d3e54e9874d839f573d8009c20154ad0f2fb0a225 deb' # deb, with old source packages
	'drupal:latest@sha256:7784aad7710a1eb78047ec6962f111c7ae65c278f51606bf65cd9976be641ed1 composer' # composer, from both "vendor/composer/installed.json" and "composer.lock"
	'mediawiki:latest@sha256:406a08c7f2cf5a9c9cb590bbe27a21b4d3cb3268b0acf327fa7dd2727ff6b0be composer' # composer, including packages only "composer.lock" knows about ("php-composer-lock")
	'rabbitmq:latest@sha256:183272aa2ff82718cabeef343de8d9a900931ea65fda4e563fed2a6d9efde578 otp' # otp ("erlang-otp-application"), plus golang binaries
	'swipl:latest@sha256:104e8fc9af7ea5c00def0aea2cba2ad1792e2f8c530b2e78432b2ee9f83494d8 swiplpack' # swiplpack ("swipl-pack-cataloger")
	'haxe:4.0.5-stretch@sha256:688a1f247933e54cf926d23926851f8d37ead222b3d5b62d0105163a37ee2d36 opam' # opam ("opam-cataloger"), which the newer tags do not have any of
)

dir="$(readlink -ve "$BASH_SOURCE")"
dir="$(dirname "$dir")"
oiDir="$(readlink -ve "$dir/../..")"

old="${1:-}"

externalPins="$("$oiDir/.external-pins/list.sh")"
indexer="$(grep <<<"$externalPins" -m1 '^docker/scout-sbom-indexer:')"
new="$(< "$("$oiDir/.external-pins/file.sh" "$indexer")")"
if [ "$old" = "$new" ]; then
	echo "$indexer is already $new; testing it on its own"
	old=
fi

# the real build environment, so we get the exact same BuildKit, "EXTRA_SCANNERS", etc
vars="$(BASHBREW_ARCH=amd64 "$oiDir/.bin/bashbrew-buildkit-env-setup.sh")"
eval "$(jq <<<"$vars" --raw-output 'to_entries[] | "export \(.key)=\(.value | @sh)"')"

# the generator above uses the pin in this checkout, so swapping digests is how we get the old one
case "$BASHBREW_BUILDKIT_SBOM_GENERATOR" in
	*"@$new"*) ;;
	*) echo >&2 "error: '$BASHBREW_BUILDKIT_SBOM_GENERATOR' does not reference '$new'"; exit 1 ;;
esac

tmp="$(mktemp --directory --tmpdir "$(basename "$BASH_SOURCE" .sh).XXXXXX")"
exitTrap="$(printf 'rm --recursive --force %q' "$tmp")"
trap "$exitTrap" EXIT

# prints the SPDX document for the given image, much like "oci-sbom.sh" in docker-library/meta-scripts
sbom() {
	local digest="$1"; shift # indexer digest
	local image="$1"; shift

	local layout="$tmp/layout"
	docker buildx build \
		--progress=plain \
		--load=false --provenance=false \
		--build-arg BUILDKIT_DOCKERFILE_CHECK=skip=all \
		--sbom=generator="${BASHBREW_BUILDKIT_SBOM_GENERATOR/"$new"/"$digest"}" \
		--output "type=oci,tar=false,dest=$layout" \
		--platform linux/amd64 \
		--build-context "fake=docker-image://$image" \
		'-' <<<'FROM fake'

	local blob
	blob="$(jq --raw-output '.manifests[0].digest' "$layout/index.json")"
	blob="$(jq --raw-output '.manifests[] | select(.annotations["vnd.docker.reference.type"] == "attestation-manifest") | .digest' "$layout/blobs/${blob/://}")"
	blob="$(jq --raw-output '.layers[] | select(.annotations["in-toto.io/predicate-type"] == "https://spdx.dev/Document") | .digest' "$layout/blobs/${blob/://}")"
	jq '.predicate' "$layout/blobs/${blob/://}"

	# the layout includes the whole image, so clean it up right away
	rm --recursive --force "$layout"
}

for entry in "${images[@]}"; do
	image="${entry%% *}"
	types="${entry#"$image"}"

	sbom "$new" "$image" > "$tmp/new.json"
	: > "$tmp/old.json"
	if [ -n "$old" ]; then
		sbom "$old" "$image" > "$tmp/old.json"
	fi

	jq --null-input --compact-output --slurpfile old "$tmp/old.json" --slurpfile new "$tmp/new.json" --arg image "${image%%@*}" --arg types "$types" '
		def purl: [ .externalRefs[]? | select(.referenceType == "purl") | .referenceLocator ][0] // "";
		def package_type: purl | capture("^pkg:(?<type>[^/]+)/").type // "none";
		def unique_packages: [ .packages[] | [ .name, .versionInfo, package_type ] ] | unique;
		def summary: {
			packages: (.packages | length),
			unique: (unique_packages | length),
			links: ([ .relationships[] | select(.relationshipType == "GENERATED_FROM") ] | length),
			types: ([ .packages[] | package_type ] | group_by(.) | map({ key: .[0], value: length }) | from_entries),
		};
		$new[0] as $n
		| $old[0] as $o
		| {
			image: $image,
			new: ($n | summary),
			old: ($o | if . then summary else null end),
			lost: (if $o then ($o | unique_packages) - ($n | unique_packages) else [] end),
			missing: (($types | split(" ") | map(select(. != ""))) - (($n | summary).types | keys)),
		}
	' >> "$tmp/reports.json"
done

echo "$indexer: ${old:+$old -> }$new"
jq --slurp --raw-output '
	def show(f): if .old then "\(.old | f) -> \(.new | f)" else "\(.new | f)" end;
	.[]
	| "\(.image)\tpackages \(show(.packages))\tunique \(show(.unique))\tgenerated-from \(show(.links))",
		"  types: \([ ((.old.types // {}) + .new.types | keys[]) as $type | "\($type)=\(if .old then "\(.old.types[$type] // 0) -> " else "" end)\(.new.types[$type] // 0)" ] | join(" "))",
		(.lost[] | "  lost: \(join(" "))"),
		(.missing[] | "  missing type: \(.)")
' "$tmp/reports.json"

bad="$(jq --slurp --raw-output '[ .[] | select(.lost != [] or .missing != []) | .image ] | join(" ")' "$tmp/reports.json")"
if [ -n "$bad" ]; then
	echo >&2 "error: lost or missing packages in: $bad"
	exit 1
fi
