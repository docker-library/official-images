#!/bin/bash
set -eo pipefail
shopt -s dotglob

# make sure we can GTFO
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

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

#dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

tempDir="$(mktemp -d)"
trap "rm -rf '$tempDir'" EXIT
cd "$tempDir"

git clone --quiet \
	https://github.com/docker-library/official-images.git \
	oi

git -C oi fetch --quiet \
	origin "pull/$pull/merge":pull

images=( "$@" )
if [ "${#images[@]}" -eq 0 ]; then
	images=( $(git -C oi/library diff --name-only HEAD...pull -- . | xargs -n1 basename) )
fi

export BASHBREW_CACHE="${BASHBREW_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/bashbrew}"
export BASHBREW_LIBRARY="$PWD/oi/library"

: "${BASHBREW_ARCH:=amd64}" # TODO something smarter with arches
export BASHBREW_ARCH

# "bashbrew cat" template for duplicating something like "bashbrew list --uniq" but with architectures too
archesListTemplate='
	{{- range $e := $.Entries -}}
		{{- range .Architectures -}}
			{{- $.RepoName -}}:{{- $e.Tags | last -}}
			{{- " @ " -}}
			{{- . -}}
			{{- "\n" -}}
		{{- end -}}
	{{- end -}}
'
# ... and SharedTags
sharedTagsListTemplate='
	{{- range $group := .Manifest.GetSharedTagGroups -}}
		{{- range $tag := $group.SharedTags -}}
			{{- join ":" $.RepoName $tag -}}
			{{- " -- " -}}
			{{- range $i, $e := $group.Entries -}}
				{{- if gt $i 0 -}}
					{{- ", " -}}
				{{- end -}}
				{{- join ":" $.RepoName ($e.Tags | last) -}}
			{{- end -}}
			{{- "\n" -}}
		{{- end -}}
	{{- end -}}
'

# TODO something less hacky than "git archive" hackery, like a "bashbrew archive" or "bashbrew context" or something
template='
	tempDir="$(mktemp -d)"
	{{- "\n" -}}
	{{- range $.Entries -}}
		{{- $arch := .HasArchitecture arch | ternary arch (.Architectures | first) -}}
		{{- $froms := $.ArchDockerFroms $arch . -}}
		{{- $outDir := join "_" $.RepoName (.Tags | last) -}}
		git -C "$BASHBREW_CACHE/git" archive --format=tar
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
		mkdir -p "$tempDir/{{- $outDir -}}" && echo "{{- .ArchFile $arch -}}" > "$tempDir/{{- $outDir -}}/.bashbrew-dockerfile-name"
		{{- "\n" -}}
	{{- end -}}
	tar -cC "$tempDir" . && rm -rf "$tempDir"
'

copy-tar() {
	local src="$1"; shift
	local dst="$1"; shift

	if [ "$allFiles" ]; then
		mkdir -p "$dst"
		cp -al "$src"/*/ "$dst/"
		return
	fi

	local d dockerfiles=()
	for d in "$src"/*/.bashbrew-dockerfile-name; do
		local bf="$(< "$d")" dDir="$(dirname "$d")"
		if [ "$bf" = 'Dockerfile' ]; then
			# "*" at the end here ensures we capture "Dockerfile.builder" style repos in a useful way too (busybox, hello-world)
			dockerfiles+=( "$dDir/$bf"* )
		else
			dockerfiles+=( "$dDir/$bf" )
		fi
		rm "$d" # remove the ".bashbrew-dockerfile-name" file we created
	done

	for d in "${dockerfiles[@]}"; do
		local dDir="$(dirname "$d")"
		local dDirName="$(basename "$dDir")"

		IFS=$'\n'
		local files=(
			"$(basename "$d")"
			$(awk '
				toupper($1) == "COPY" || toupper($1) == "ADD" {
					for (i = 2; i < NF; i++) {
						if ($i !~ /^--chown=/) {
							print $i
						}
					}
				}
			' "$d")

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
			globbed=( $(cd "$dDir" && find -path "./$findGlobbedPath") )
			if [ "${#globbed[@]}" -eq 0 ]; then
				globbed=( "$f" )
			fi

			local g
			for g in "${globbed[@]}"; do
				if [ -z "$failureMatters" ] && [ ! -e "$dDir/$g" ]; then
					continue
				fi

				mkdir -p "$(dirname "$dst/$dDirName/$g")"
				cp -alT "$dDir/$g" "$dst/$dDirName/$g"

				if [ "$listTarballContents" ]; then
					case "$g" in
						*.tar.*|*.tgz)
							tar -tf "$dst/$dDirName/$g" \
								| grep -vE "$uninterestingTarballGrep" \
								| sed -e 's!^[.]/!!' \
								| sort \
								> "$dst/$dDirName/$g  'tar -t'"
							;;
					esac
				fi
			done
		done
	done
}

mkdir temp
git -C temp init --quiet

bashbrew list "${images[@]}" | sort -uV > temp/_bashbrew-list || :
bashbrew cat --format "$archesListTemplate" "${images[@]}" | sort -V > temp/_bashbrew-arches || :
bashbrew cat --format "$sharedTagsListTemplate" "${images[@]}" | grep -vE '^$' | sort -V > temp/_bashbrew-shared-tags || :
for image in "${images[@]}"; do
	if script="$(bashbrew cat -f "$template" "$image")"; then
		mkdir tar
		( eval "$script" | tar -xiC tar )
		copy-tar tar temp
		rm -rf tar
	fi
done
git -C temp add . || :
git -C temp commit --quiet --allow-empty -m 'initial' || :

git -C oi checkout --quiet pull

git -C temp rm --quiet -rf . || :
bashbrew list "${images[@]}" | sort -uV > temp/_bashbrew-list || :
bashbrew cat --format "$archesListTemplate" "${images[@]}" | sort -V > temp/_bashbrew-arches || :
bashbrew cat --format "$sharedTagsListTemplate" "${images[@]}" | grep -vE '^$' | sort -V > temp/_bashbrew-shared-tags || :
script="$(bashbrew cat -f "$template" "${images[@]}")"
mkdir tar
( eval "$script" | tar -xiC tar )
copy-tar tar temp
rm -rf tar
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
