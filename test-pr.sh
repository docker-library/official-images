#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

usage() {
	cat <<-EOUSAGE
		usage: $0 [PR number] [repo[:tag]]
		   ie: $0 1024
		       $0 9001 debian php django
		
		This script builds and tests the specified pull request to official-images and
		provides ouput in markdown for commenting on the pull request.
	EOUSAGE
}

pull="$1"
shift || { usage >&2 && exit 1; }

url="https://github.com/docker-library/official-images/pull/$pull.patch"
pat="$(curl -fsSL --compressed "$url")"
commit="$(echo "$pat" | grep -E '^From [0-9a-f]+ ' | tail -n1 | cut -d' ' -f2)"

if [ "$#" -eq 0 ]; then
	IFS=$'\n'
	files=( $(echo "$pat" | awk -F '/' '$1 == "+++ b" && $2 == "library" { print $3 }' | sort -u) )
	unset IFS
else
	files=( "$@" )
fi

if [ ${#files[@]} -eq 0 ]; then
	echo >&2 'no files in library/ changed in PR #'"$pull"
	exit 0
fi

urls=()
for f in "${files[@]}"; do
	urls+=( "https://raw.githubusercontent.com/docker-library/official-images/$commit/library/$f" )
done

join() {
	sep="$1"
	arg1="$2"
	shift 2
	echo -n "$arg1"
	[ $# -gt 0 ] && printf "${sep}%s" "$@"
}

echo 'Build test of' '#'"$pull"';' "$commit" '(`'"$(join '`, `' "${files[@]}")"'`):'
failed=
for url in "${urls[@]}"; do
	echo
	echo '```console'
	echo '$ url="'"$url"'"'
	echo '$ bashbrew build "$url"'
	if ./bashbrew/bashbrew.sh build "$url"; then
		echo '$ bashbrew list --uniq "$url" | xargs test/run.sh'
		if ! ./bashbrew/bashbrew.sh list --uniq "$url" | xargs ./test/run.sh; then
			failed=1
		fi
	else
		failed=1
	fi
	echo '```'
done
if [ "$failed" ]; then
	echo
	echo 'There is at least one failure in the above build log.'
fi
