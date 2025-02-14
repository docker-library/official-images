#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s dotglob

# make sure we can GTFO
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# if bashbrew is missing, bail early with a sane error
bashbrew --version > /dev/null

usage() {
	cat <<-EOUSAGE
		usage: $0 [PR number] [repo[:tag]]
		   ie: $0 1024
		       $0 9001 debian php django
	EOUSAGE
}

# TODO flags parsing
allFiles=
listTarballContents=1
findCopies='20%'

uninterestingTarballContent=(
	# "config_diff_2017_01_07.log"
	'var/log/YaST2/'

	# "ks-script-mqmz_080.log"
	# "ks-script-ycfq606i.log"
	'var/log/anaconda/'

	# "2016-12-20/"
	'var/lib/yum/history/'
	'var/lib/dnf/history/'

	# "a/f8c032d2be757e1a70f00336b55c434219fee230-acl-2.2.51-12.el7-x86_64/var_uuid"
	'var/lib/yum/yumdb/'
	'var/lib/dnf/yumdb/'

	# "b42ff584.0"
	'etc/pki/tls/rootcerts/'

	# "09/401f736622f2c9258d14388ebd47900bbab126"
	'usr/lib/.build-id/'
)

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

uninterestingTarballGrep="^([.]?/)?($(join '|' "${uninterestingTarballContent[@]}"))"

if [ "$#" -eq 0 ]; then
	usage >&2
	exit 1
fi
pull="$1" # PR number
shift

diffDir="$(readlink -f "$BASH_SOURCE")"
diffDir="$(dirname "$diffDir")"

tempDir="$(mktemp -d)"
trap "rm -rf '$tempDir'" EXIT
cd "$tempDir"

git clone --quiet \
	https://github.com/docker-library/official-images.git \
	oi

if [ "$pull" != '0' ]; then
	git -C oi fetch --quiet \
		origin "pull/$pull/merge":refs/heads/pull
else
	git -C oi fetch --quiet --update-shallow \
		"$diffDir" HEAD:refs/heads/pull
fi

externalPins=
if [ "$#" -eq 0 ]; then
	externalPins="$(git -C oi/.external-pins diff --no-renames --name-only HEAD...pull -- '*/**')"

	images="$(git -C oi/library diff --no-renames --name-only HEAD...pull -- .)"
	if [ -z "$images" ] && [ -z "$externalPins" ]; then
		exit 0
	fi
	images="$(xargs -rn1 basename <<<"$images")"
	set -- $images
fi

export BASHBREW_LIBRARY="$PWD/oi/library"

: "${BASHBREW_ARCH:=amd64}" # TODO something smarter with arches
export BASHBREW_ARCH

# TODO something less hacky than "git archive" hackery, like a "bashbrew archive" or "bashbrew context" or something
template='
	tempDir="$(mktemp -d)"
	{{- "\n" -}}
	{{- range $.Entries -}}
		{{- $arch := .HasArchitecture arch | ternary arch (.Architectures | first) -}}
		{{- /* cannot replace ArchDockerFroms with bashbrew fetch or the arch selector logic has to be duplicated 🥹*/ -}}
		{{- $froms := $.ArchDockerFroms $arch . -}}
		{{- $outDir := join "_" $.RepoName (.Tags | last) -}}
		git -C "{{ gitCache }}" archive --format=tar
		{{- " " -}}
		{{- "--prefix=" -}}
		{{- $outDir -}}
		{{- "/" -}}
		{{- " " -}}
		{{- .ArchGitCommit $arch -}}
		{{- ":" -}}
		{{- $dir := .ArchDirectory $arch -}}
		{{- (eq $dir ".") | ternary "" $dir -}}
		{{- "\n" -}}
		mkdir -p "$tempDir/{{- $outDir -}}" && echo "{{- .ArchBuilder $arch -}}" > "$tempDir/{{- $outDir -}}/.bashbrew-builder" && echo "{{- .ArchFile $arch -}}" > "$tempDir/{{- $outDir -}}/.bashbrew-file"
		{{- "\n" -}}
	{{- end -}}
	tar -cC "$tempDir" . && rm -rf "$tempDir"
'

_tar-t() {
	tar -t "$@" \
		| grep -vE "$uninterestingTarballGrep" \
		| sed -e 's!^[.]/!!' \
			-r \
			-e 's!([/.-]|^)((lib)?(c?python|py)-?)[0-9]+([.][0-9]+)?([/.-]|$)!\1\2XXX\6!g' \
		| sort
}

_jq() {
	if [ "$#" -eq 0 ]; then
		set -- '.'
	fi
	jq --tab -S "$@"
}

copy-tar() {
	local src="$1"; shift
	local dst="$1"; shift

	if [ -n "$allFiles" ]; then
		mkdir -p "$dst"
		cp -al "$src"/*/ "$dst/"
		return
	fi

	local d indexes=() dockerfiles=()
	for d in "$src"/*/.bashbrew-file; do
		[ -f "$d" ] || continue
		local bf; bf="$(< "$d")"
		local dDir; dDir="$(dirname "$d")"
		local builder; builder="$(< "$dDir/.bashbrew-builder")"
		if [ "$builder" = 'oci-import' ]; then
			indexes+=( "$dDir/$bf" )
		else
			dockerfiles+=( "$dDir/$bf" )
			if [ "$bf" = 'Dockerfile' ]; then
				# if "Dockerfile.builder" exists, let's check that too (busybox, hello-world)
				if [ -f "$dDir/$bf.builder" ]; then
					dockerfiles+=( "$dDir/$bf.builder" )
				fi
			fi
		fi
		rm "$d" "$dDir/.bashbrew-builder" # remove the ".bashbrew-*" files we created
	done

	# now that we're done with our globbing needs, let's disable globbing so it doesn't give us wrong answers
	local -
	set -o noglob

	for i in "${indexes[@]}"; do
		local iName; iName="$(basename "$i")"
		local iDir; iDir="$(dirname "$i")"
		local iDirName; iDirName="$(basename "$iDir")"
		local iDst="$dst/$iDirName"

		mkdir -p "$iDst"

		_jq . "$i" > "$iDst/$iName"

		local digest
		digest="$(jq -r --arg name "$iName" '
			if $name == "index.json" then
				.manifests[0].digest
			else
				.digest
			end
		' "$i")"

		local blob="blobs/${digest//://}"
		local blobDir; blobDir="$(dirname "$blob")"
		local manifest="$iDir/$blob"
		mkdir -p "$iDst/$blobDir"
		_jq . "$manifest" > "$iDst/$blob"

		local configDigest; configDigest="$(jq -r '.config.digest' "$manifest")"
		local blob="blobs/${configDigest//://}"
		local blobDir; blobDir="$(dirname "$blob")"
		local config="$iDir/$blob"
		mkdir -p "$iDst/$blobDir"
		_jq . "$config" > "$iDst/$blob"

		local layers
		layers="$(jq -r '[ .layers[].digest | @sh ] | join(" ")' "$manifest")"
		eval "layers=( $layers )"
		local layerDigest
		for layerDigest in "${layers[@]}"; do
			local blob="blobs/${layerDigest//://}"
			local blobDir; blobDir="$(dirname "$blob")"
			local layer="$iDir/$blob"
			mkdir -p "$iDst/$blobDir"
			_tar-t -f "$layer" > "$iDst/$blob  'tar -t'"
		done
	done

	for d in "${dockerfiles[@]}"; do
		local dDir; dDir="$(dirname "$d")"
		local dDirName; dDirName="$(basename "$dDir")"

		# TODO choke on "syntax" parser directive
		# TODO handle "escape" parser directive reasonably
		local flatDockerfile; flatDockerfile="$(
			gawk '
				BEGIN { line = "" }
				/^[[:space:]]*#/ {
					gsub(/^[[:space:]]+/, "")
					print
					next
				}
				{
					if (match($0, /^(.*)(\\[[:space:]]*)$/, m)) {
						line = line m[1]
						next
					}
					print line $0
					line = ""
				}
			' "$d"
		)"

		local IFS=$'\n'
		local copyAddContext; copyAddContext="$(awk '
			toupper($1) == "COPY" || toupper($1) == "ADD" {
				for (i = 2; i < NF; i++) {
					if ($i ~ /^--from=/) {
						next
					}
					# COPY and ADD options
					if ($i ~ /^--(chown|chmod|link|parents|exclude)=/) {
						continue
					}
					# additional ADD options
					if ($i ~ /^--(keep-git-dir|checksum)=/) {
						continue
					}
					for ( ; i < NF; i++) {
						print $i
					}
				}
			}
		' <<<"$flatDockerfile")"
		local dBase; dBase="$(basename "$d")"
		local files=(
			"$dBase"
			$copyAddContext

			# some extra files which are likely interesting if they exist, but no big loss if they do not
			' .dockerignore' # will be used automatically by "docker build"
			' *.manifest' # debian/ubuntu "package versions" list
			' *.ks' # fedora "kickstart" (rootfs build script)
			' build*.txt' # ubuntu "build-info.txt", debian "build-command.txt"

			# usefulness yet to be proven:
			#' *.log'
			#' {MD5,SHA1,SHA256}SUMS'
			#' *.{md5,sha1,sha256}'

			# (the space prefix is removed below and is used to ignore non-matching globs so that bad "Dockerfile" entries appropriately lead to failure)
		)
		unset IFS

		mkdir -p "$dst/$dDirName"

		local f origF failureMatters
		for origF in "${files[@]}"; do
			f="${origF# }" # trim off leading space (indicates we don't care about failure)
			[ "$f" = "$origF" ] && failureMatters=1 || failureMatters=

			local globbed
			# "find: warning: -path ./xxx/ will not match anything because it ends with /."
			local findGlobbedPath="${f%/}"
			findGlobbedPath="${findGlobbedPath#./}"
			local globbedStr; globbedStr="$(cd "$dDir" && find -path "./$findGlobbedPath")"
			local -a globbed=( $globbedStr )
			if [ "${#globbed[@]}" -eq 0 ]; then
				globbed=( "$f" )
			fi

			local g
			for g in "${globbed[@]}"; do
				local srcG="$dDir/$g" dstG="$dst/$dDirName/$g"

				if [ -z "$failureMatters" ] && [ ! -e "$srcG" ]; then
					continue
				fi

				local gDir; gDir="$(dirname "$dstG")"
				mkdir -p "$gDir"
				cp -alT "$srcG" "$dstG"

				if [ -n "$listTarballContents" ]; then
					case "$g" in
						*.tar.* | *.tgz)
							if [ -s "$dstG" ]; then
								_tar-t -f "$dstG" > "$dstG  'tar -t'"
							fi
							;;
					esac
				fi
			done
		done
	done
}

# a "bashbrew cat" template that gives us the last / "least specific" tags for the arguments
# (in other words, this is "bashbrew list --uniq" but last instead of first)
templateLastTags='
	{{- range .TagEntries -}}
		{{- $.RepoName -}}
		{{- ":" -}}
		{{- .Tags | last -}}
		{{- "\n" -}}
	{{- end -}}
'

_metadata-files() {
	if [ "$#" -gt 0 ]; then
		bashbrew list "$@" 2>>temp/_bashbrew.err | sort -uV > temp/_bashbrew-list || :

		bashbrew cat --format '{{ range .Entries }}{{ range .Architectures }}{{ . }}{{ "\n" }}{{ end }}{{ end }}' "$@" 2>>temp/_bashbrew.err | sort -u > temp/_bashbrew-arches || :

		"$diffDir/_bashbrew-cat-sorted.sh" "$@" 2>>temp/_bashbrew.err > temp/_bashbrew-cat || :

		# piping "bashbrew list" first so that .TagEntries is filled up (keeping "templateLastTags" simpler)
		# sorting that by version number so it's ~stable
		# then doing --build-order on that, which is a "stable sort"
		# then redoing that list back into "templateLastTags" so we get the tags we want listed (not the tags "--uniq" chooses)
		bashbrew list --uniq "$@" \
			| xargs -r bashbrew cat --format "$templateLastTags" \
			| sort -V \
			| xargs -r bashbrew list --uniq --build-order 2>>temp/_bashbrew.err \
			| xargs -r bashbrew cat --format "$templateLastTags" 2>>temp/_bashbrew.err \
			> temp/_bashbrew-list-build-order || :

		# oci images can't be fetched with ArchDockerFroms
		# todo: use each first arch instead of current arch
		bashbrew fetch --arch-filter "$@"
		script="$(bashbrew cat --format "$template" "$@")"
		mkdir tar
		( eval "$script" | tar -xiC tar )
		copy-tar tar temp
		rm -rf tar

		# TODO we should *also* validate that our lists ended up non-empty 😬
		cat >&2 temp/_bashbrew.err
	fi

	if [ -n "$externalPins" ] && command -v crane &> /dev/null; then
		local file
		for file in $externalPins; do
			[ -e "oi/$file" ] || continue
			local pin digest dir
			pin="$("$diffDir/.external-pins/tag.sh" "$file")"
			digest="$(< "oi/$file")"
			dir="temp/$file"
			mkdir -p "$dir"
			bashbrew remote arches --json "$pin@$digest" | _jq > "$dir/bashbrew.json"
			local manifests manifest
			manifests="$(jq -r '
				[ (
					.arches
					| if has(env.BASHBREW_ARCH) then
						.[env.BASHBREW_ARCH]
					else
						.[keys_unsorted | first]
					end
				)[].digest | @sh ]
				| join(" ")
			' "$dir/bashbrew.json")"
			eval "manifests=( $manifests )"
			for manifest in "${manifests[@]}"; do
				crane manifest "$pin@$manifest" | _jq > "$dir/manifest-${manifest//:/_}.json"
				local config
				config="$(jq -r '.config.digest' "$dir/manifest-${manifest//:/_}.json")"
				crane blob "$pin@$config" | _jq > "$dir/manifest-${manifest//:/_}-config.json"
			done
		done
	fi
}

mkdir temp
git -C temp init --quiet
git -C temp config user.name 'Bogus'
git -C temp config user.email 'bogus@bogus'

# handle "new-image" PRs gracefully
for img; do touch "$BASHBREW_LIBRARY/$img"; [ -s "$BASHBREW_LIBRARY/$img" ] || echo 'Maintainers: New Image! :D (@docker-library-bot)' > "$BASHBREW_LIBRARY/$img"; done

_metadata-files "$@"
git -C temp add . || :
git -C temp commit --quiet --allow-empty -m 'initial' || :

git -C oi clean --quiet --force
git -C oi checkout --quiet pull

# handle "deleted-image" PRs gracefully :(
for img; do touch "$BASHBREW_LIBRARY/$img"; [ -s "$BASHBREW_LIBRARY/$img" ] || echo 'Maintainers: Deleted Image D: (@docker-library-bot)' > "$BASHBREW_LIBRARY/$img"; done

git -C temp rm --quiet -rf . || :

_metadata-files "$@"
git -C temp add .

git -C temp diff \
	--find-copies-harder \
	--find-copies="$findCopies" \
	--find-renames="$findCopies" \
	--ignore-blank-lines \
	--ignore-space-at-eol \
	--ignore-space-change \
	--irreversible-delete \
	--minimal \
	--staged
