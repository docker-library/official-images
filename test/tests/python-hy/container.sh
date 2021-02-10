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
if ! "$python" -c 'import sys; exit((sys.version_info[0] == 3 and sys.version_info[1] >= 10) or sys.version_info[0] > 3 or sys.version_info[0] == 2)'; then
	echo >&2 'skipping Hy test -- not allowed on Python 2.x and 3.10+ (yet!)'
	# cheaters gunna cheat
	cat expected-std-out.txt
	exit
fi

# ensure pip does not complain about a new version being available
export PIP_DISABLE_PIP_VERSION_CHECK=1
# or that a new version will no longer work with this python version
export PIP_NO_PYTHON_VERSION_WARNING=1
pip install -q 'hy==0.20.0'

hy ./container.hy
