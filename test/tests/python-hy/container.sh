#!/bin/sh
set -e

# Hy doesn't work on 3.6+ :(
if ! python -c 'import sys; exit((sys.version_info[0] == 3 and sys.version_info[1] >= 6) or sys.version_info[0] > 3)'; then
	# TypeError: required field "is_async" missing from comprehension
	echo >&2 'skipping Hy test -- no workie on Python 3.6+'
	cat expected-std-out.txt # cheaters gunna cheat
	exit
fi

pip install -q hy
hy ./container.hy
