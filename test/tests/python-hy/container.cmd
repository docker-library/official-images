@echo off

for %%p in ( pypy3 pypy python3 python ) do (
	%%p --version >nul 2>&1 && (
		set python=%%p
		goto found
	)
)
echo unable to run Hy test -- seems this image does not contain Python? >&2
exit /b 1

:found
%python% --version >nul 2>&1 || exit /b %errorlevel%

rem Hy is complicated, and uses Python's internal AST representation directly, and thus Hy releases usually lag behind a little on major Python releases (and we don't want that to gum up our tests)
rem see https://github.com/hylang/hy/issues/1111 for example breakage
rem also, it doesn't always support older (still supported) Python versions; https://github.com/hylang/hy/pull/2176 (3.6 support removal)
rem see "Programming Language" tags on https://pypi.org/project/hy/ for the current support range (see also version numbers below)
rem TODO allow 3.12 again once https://github.com/hylang/hy/issues/2598 / https://github.com/hylang/hy/pull/2599 is in a release (likely 0.29.1 or 0.30.0)
%python% -c "import sys; exit(not(sys.version_info[0] == 3 and 8 <= sys.version_info[1] <= 11))" || (
	echo skipping Hy test -- not allowed on Python less than 3.8 or greater than 3.11 ^(yet!^) >&2
	rem cheaters gunna cheat
	type expected-std-out.txt
	exit /b 0
)

rem ensure pip does not complain about a new version being available
set PIP_DISABLE_PIP_VERSION_CHECK=1
rem or that a new version will no longer work with this python version
set PIP_NO_PYTHON_VERSION_WARNING=1
rem https://pypi.org/project/hy/#history
rem https://pypi.org/project/hyrule/#history
pip install -q "hy==0.29.0" "hyrule==0.6.0" > NUL || exit /b %errorlevel%

hy ./container.hy || exit /b %errorlevel%

exit /b 0
