#!/bin/sh
set -eu

python=
for c in pypy3 pypy python3 python; do
	if [ -x "/usr/local/bin/$c" ]; then
		python="/usr/local/bin/$c"
		break
	fi
done

if [ -z "$python" ]; then
	echo >&2 'unable to run Hy test -- seems this image does not contain Python?'
	exit 1
fi

# Hy is complicated, and uses Python's internal AST representation directly, and thus Hy releases usually lag behind a little on major Python releases (and we don't want that to gum up our tests)
# see https://github.com/hylang/hy/issues/1111 for example breakage
# also, it doesn't always support older (still supported) Python versions; https://github.com/hylang/hy/pull/2176 (3.6 support removal)
# see "Programming Language" tags on https://pypi.org/project/hy/ for the current support range (see also version numbers below)
# TODO allow 3.12 again once https://github.com/hylang/hy/issues/2598 / https://github.com/hylang/hy/pull/2599 is in a release (likely 0.29.1 or 0.30.0)
if ! "$python" -c 'import sys; exit(not(sys.version_info[0] == 3 and 8 <= sys.version_info[1] <= 11))'; then
	echo >&2 'skipping Hy test -- not allowed on Python less than 3.8 or greater than 3.11 (yet!)'
	# cheaters gunna cheat
	cat expected-std-out.txt
	exit
fi

(
	# ensure pip does not complain about a new version being available
	export PIP_DISABLE_PIP_VERSION_CHECK=1
	# or that a new version will no longer work with this python version
	export PIP_NO_PYTHON_VERSION_WARNING=1
	# ensure pip does not complain about running about root
	export PIP_ROOT_USER_ACTION=ignore

	# https://pypi.org/project/hy/#history
	# https://pypi.org/project/hyrule/#history
	pip install -q 'hy==0.29.0' 'hyrule==0.6.0' > /dev/null
)

hy ./container.hy
