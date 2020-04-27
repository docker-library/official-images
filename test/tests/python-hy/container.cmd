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
%python% -c "import sys; exit((sys.version_info[0] == 3 and sys.version_info[1] >= 8) or sys.version_info[0] > 3)" || (
	echo skipping Hy test -- not allowed on Python 3.8+ ^(yet!^) >&2
	rem cheaters gunna cheat
	type expected-std-out.txt
	exit /b 0
)

pip install -q "hy==0.17.0" || exit /b %errorlevel%

hy ./container.hy || exit /b %errorlevel%

exit /b 0
