#!/bin/sh
set -e

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
if ! "$python" -c 'import sys; exit((sys.version_info[0] == 3 and sys.version_info[1] >= 8) or sys.version_info[0] > 3)'; then
	echo >&2 'skipping Hy test -- not allowed on Python 3.8+ (yet!)'
	cat expected-std-out.txt # cheaters gunna cheat
	exit
fi

pip install -q 'hy==0.16.0'
hy ./container.hy
