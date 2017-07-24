#!/bin/bash
set -eu -o pipefail

# set "$0" so that tmux shows something more useful than "bash" in the statusbar
desired0='b-a-p'
if ! grep -q "$desired0" "/proc/$$/cmdline"; then
	exec -a "$desired0" "$SHELL" -- "$BASH_SOURCE" "$@"
fi

if [ "$#" -eq 0 ]; then
	self="$(basename "$0")"
	cat >&2 <<-EOF
		error: missing arguments
		usage: $self <build args>
		   ie: $self debian ubuntu
	EOF
	exit 1
fi

# allow for specifying an alternate path to "bashbrew"
: "${BASHBREW:=bashbrew}"

# normalize "$@" to be the "--uniq" versions (and deduplicate)
# also grab the list of associated repos in explicit build order (so we can build/push grouped by repo)
IFS=$'\n'
set -- $("$BASHBREW" list --uniq --repos "$@" | sort -u | xargs "$BASHBREW" list --uniq --repos --build-order --apply-constraints)
repos=( $(echo "$*" | cut -d: -f1 | xargs "$BASHBREW" list --repos --build-order --apply-constraints) )
unset IFS

declare -A repoTags=()
for repoTag; do
	repo="${repoTag%%:*}"
	repoTags[$repo]+=" $repoTag"
done

# fill "$@" back up with the corrected build order (especially for the "Children:" output)
set --
for repo in "${repos[@]}"; do
	set -- "$@" ${repoTags[$repo]}
done

children="$("$(dirname "$BASH_SOURCE")/children.sh" "$@")"

echo
echo
echo "Children: (of $*)"
echo "${children:-<none>}"
echo
echo

for repo in "${repos[@]}"; do
	tags=( ${repoTags[$repo]} )
	(
		set -x
		time "$BASHBREW" build "${tags[@]}"
		time "$BASHBREW" tag "${tags[@]}"
		time "$BASHBREW" push "${tags[@]}"
	)
done

echo
echo
echo "Children: (of $*)"
echo "${children:-<none>}"
echo
echo

if [ "$children" ]; then
	echo 'Suggested command:'
	echo "  ./children.sh $* | xargs ./build-and-push.sh"
	echo
fi

# end by printing only warnings (stderr) for images we skipped (such as "windowsservercore" when building on Linux)
# this helps remind us to switch BASHBREW or servers
"$BASHBREW" list --apply-constraints "$@" > /dev/null
