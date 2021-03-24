#!/bin/bash
set -e

IFS=$'\n'
userPasswds=( $(docker run --rm --user 0:0 --entrypoint cut "$1" -d: -f1-2 /etc/passwd) )
userShadows=()
if grep -qE ':x$' <<<"${userPasswds[*]}"; then
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

	if [ -z "$pass" ]; then
		# for root this is a security vulnerability (see CVE-2019-5021, for example)
		if [ "$user" = 'root' ]; then
			echo >&2 "error: empty password detected for '$user'"
			ret=1
		else
			echo >&2 "warning: empty password detected for '$user'"
		fi
		continue
	fi

	if [ "$pass" = '*' ]; then
		# "If the password field contains some string that is not a valid result of crypt(3), for instance ! or *, the user will not be able to use a unix password to log in (but the user may log in the system by other means)."
		# (Debian uses this for having default-provided accounts without a password but also without being explicitly locked, for example)
		continue
	fi

	if [ "${pass:0:1}" = '!' ]; then
		# '!anything' means "locked" password
		#echo >&2 "warning: locked password detected for '$user': '$pass'"
		continue
	fi

	if [ "${pass:0:1}" = '$' ]; then
		# gotta be crypt ($id$salt$encrypted), must be a fail
		if [[ "$1" == cirros* ]] && [ "$user" = 'cirros' ]; then
			# cirros is "supposed" to have a password for the cirros user
			# https://github.com/cirros-dev/cirros/tree/68771c7620ec100db4afb75dc4c145f4e49fe7fc#readme
			echo >&2 "warning: CirrOS has a password for the 'cirros' user (as intended)"
			continue
		fi
		echo >&2 "error: crypt password detected for '$user': '$pass'"
		ret=1
		continue
	fi

	echo >&2 "warning: garbage password detected for '$user': '$pass'"
done

exit "$ret"
