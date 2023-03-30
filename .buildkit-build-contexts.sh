#!/usr/bin/env bash
set -Eeuo pipefail

# given a list of image references, returns an appropriate list of "ref=docker-image://foo@sha256:xxx" for the current architecture

dir="$(dirname "$BASH_SOURCE")"

[ -n "$BASHBREW_ARCH" ]
archNamespace=

die() {
	echo >&2 "error: $*"
	exit 1
}

for img; do
	lookup=
	case "$img" in
		*@sha256:*)
			lookup="$img"
			;;

		*/*)
			file="$("$dir/.external-pins/file.sh" "$img")" || die "'$img': failed to look up external pin file"
			digest="$(< "$file")" || die "'$img': failed to read external pin file ('$file')"
			[ -n "$digest" ] || die "'$img': empty external pin file ('$file')"
			lookup="${img%@*}@$digest" # img should never have an @ in it here, but just in case
			;;

		*)
			[ -n "$BASHBREW_ARCH_NAMESPACES" ] || die 'missing BASHBREW_ARCH_NAMESPACES'
			archNamespace="${archNamespace:-$(bashbrew cat --format '{{ archNamespace arch }}' "$dir/library/hello-world")}"
			[ -n "$archNamespace" ] || die "failed to get arch namespace for '$BASHBREW_ARCH'"
			lookup="$archNamespace/$img"
			;;
	esac
	[ -n "$lookup" ] || die "'$img': failed to determine what image to query"

	json="$(bashbrew remote arches --json "$lookup" || die "'$img': failed lookup ('$lookup')")"
	digests="$(jq <<<"$json" -r '.arches[env.BASHBREW_ARCH] // [] | map(.digest | @sh) | join(" ")')"
	eval "digests=( $digests )"

	if [ "${#digests[@]}" -gt 1 ]; then
		echo >&2 "warning: '$lookup' has ${#digests[@]} images for '$BASHBREW_ARCH'; returning only the first"
	fi

	for digest in "${digests[@]}"; do
		echo "$img=docker-image://${lookup%@*}@$digest"
		continue 2
	done

	digest="$(jq <<<"$json" -r '.desc.digest')"
	arches="$(jq <<<"$json" -r '.arches | keys | join(" ")')"
	die "'$img': no appropriate digest for '$BASHBREW_ARCH' found in '$lookup' ('$digest'; arches '$arches')"
done
