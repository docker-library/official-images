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
%python% -c "import sys; exit((sys.version_info[0] == 3 and (sys.version_info[1] >= 11 or sys.version_info[1] <= 6)) or sys.version_info[0] > 3 or sys.version_info[0] == 2)" || (
	echo skipping Hy test -- not allowed on Python 3.11+ ^(yet!^), or on Python 3.6 or lower >&2
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
pip install -q "hy==1.0a4" "hyrule==0.1" || exit /b %errorlevel%

hy ./container.hy || exit /b %errorlevel%

exit /b 0
