#!/bin/bash
set -e

IFS=$'\n'
userPasswds=( $(docker run --rm --user 0:0 --entrypoint cut "$1" -d: -f1-2 /etc/passwd) )
userShadows=()
if echo "${userPasswds[*]}" | grep -qE ':x$'; then
	userShadows=( $(docker run --rm --user 0:0 --entrypoint cut "$1" -d: -f1-2 /etc/shadow || true) )
fi
unset IFS

declare -A passwds=()
for userPasswd in "${userPasswds[@]}"; do
	user="${userPasswd%%:*}"
	pass="${userPasswd#*:}"
	passwds[$user]="$pass"
done
for userShadow in "${userShadows[@]}"; do
	user="${userShadow%%:*}"
	if [ "${passwds[$user]}" = 'x' ]; then
		pass="${userShadow#*:}"
		passwds[$user]="$pass"
	fi
done

ret=0
for user in "${!passwds[@]}"; do
	pass="${passwds[$user]}"

	if [ -z "$pass" -o '*' = "$pass" ]; then
		# '*' and '' mean no password
		continue
	fi

	if [ "${pass:0:1}" = '!' ]; then
		# '!anything' means "locked" password
		#echo >&2 "warning: locked password detected for '$user': '$pass'"
		continue
	fi

	if [ "${pass:0:1}" = '$' ]; then
		# gotta be crypt ($id$salt$encrypted), must be a fail
		echo >&2 "error: crypt password detected for '$user': '$pass'"
		ret=1
		continue
	fi

	echo >&2 "warning: garbage password detected for '$user': '$pass'"
done

exit "$ret"
