#!/bin/bash
set -eu -o pipefail

desired0='b-a-p'
if ! grep -q "$desired0" "/proc/$$/cmdline"; then
	exec -a "$desired0" "$SHELL" -- "$BASH_SOURCE" "$@"
fi

: "${BASHBREW:=bashbrew}"

IFS=$'\n'
set -- $("$BASHBREW" list --uniq --repos --build-order "$@")
unset IFS

# set -- buildpack-deps; comm -13 <(bashbrew list "$@" | sort) <(bashbrew children "$@" | sort) | xargs bashbrew list --uniq | sort -u | xargs bashbrew list --uniq --build-order
children="$("$(dirname "$BASH_SOURCE")/children.sh" "$@")"
: "${children:=<none>}"

echo
echo
echo "Children: (of $*)"
echo "$children"
echo
echo

for repo; do
	(
		set -x
		time "$BASHBREW" build "$repo"
		time "$BASHBREW" tag "$repo"
		time "$BASHBREW" push "$repo"
	)
done

echo
echo
echo "Children: (of $*)"
echo "$children"
echo
echo

if [ "$children" != '<none>' ]; then
	echo 'Suggested command:'
	echo "  ./children.sh $* | xargs ./build-and-push.sh"
	echo
fi

"$BASHBREW" list --apply-constraints "$@" > /dev/null
