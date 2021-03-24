#!/usr/bin/env bash
set -Eeuo pipefail

testDir="$(dirname "$BASH_SOURCE")"
testDir="$(readlink -f "$testDir")"
runDir="$(readlink -f "$BASH_SOURCE")"
runDir="$(dirname "$runDir")"

case "$1" in
	*windowsservercore* | *nanoserver*)
		# https://stackoverflow.com/q/34491463/433558 -- cmd doesn't process past the first newline in the string passed on the command line, even though CreateProcess supports passing newlines??
		# https://stackoverflow.com/a/52003129/433558 -- no goto / labels in cmd argument either??  what's even the point??
		# -- "And, in any case, remember that the longest command line you can write is 8191 characters long."  ...
		# cmd /C 'for %x in ( foo bar baz ) do ( echo %x ) & echo hi' runs '( echo %x ) & echo hi' every iteration.........
		# so we'll just run twice and use the bash we're in to do the "difficult" work of a fallback when python can't be found... (even though every container has a higher cost on Windows ;.;)
		python="$(docker run --rm --entrypoint cmd "$1" /Q /S /C 'for %p in ( pypy3 pypy python3 python ) do ( %p --version >nul 2>&1 && echo %p && exit 0 )' | tr -d '\r')"
		python="${python% }" # "echo %p && ..." will print the trailing space because cmd...
		if [ -z "$python" ]; then
			echo >&2 'error: unable to determine how to run python'
			exit 1
		fi

		# ensure pip does not complain about a new version being available
		# or that a new version will no longer work with this python version
		source "$runDir/run-in-container.sh" \
			--docker-arg --env=PIP_DISABLE_PIP_VERSION_CHECK=1 \
			--docker-arg --env=PIP_NO_PYTHON_VERSION_WARNING=1 \
			"$testDir" "$1" "$python" container.py
		;;

	*)
		# ensure pip does not complain about a new version being available
		# or that a new version will no longer work with this python version
		source "$runDir/run-in-container.sh" \
			--docker-arg --env=PIP_DISABLE_PIP_VERSION_CHECK=1 \
			--docker-arg --env=PIP_NO_PYTHON_VERSION_WARNING=1 \
			"$testDir" "$1" sh -ec '
				for c in pypy3 pypy python3 python; do
					if [ -x "/usr/local/bin/$c" ]; then
						exec "/usr/local/bin/$c" "$@"
					fi
				done
				echo >&2 "error: unable to determine how to run python"
				exit 1
			'  -- ./container.py
		;;
esac
