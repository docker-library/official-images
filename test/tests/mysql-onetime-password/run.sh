#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

export MYSQL_ROOT_PASSWORD='this is an example test password'
export MYSQL_USER='0123456789012345' # "ERROR: 1470  String 'my cool mysql user' is too long for user name (should be no longer than 16)"
export MYSQL_PASSWORD='my cool mysql password'
export MYSQL_DATABASE='my cool mysql database'

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ONETIME_PASSWORD=1 \
		-e MYSQL_ROOT_PASSWORD \
		-e MYSQL_USER \
		-e MYSQL_PASSWORD \
		-e MYSQL_DATABASE \
		--name "$cname" \
		"$image"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

# connect as MYSQL_USER, needed for retry.sh
mysql() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint mysql \
		-e MYSQL_PWD="$MYSQL_PASSWORD" \
		"$image" \
		-hmysql \
		-u"$MYSQL_USER" \
		--silent \
		"$@" \
		"$MYSQL_DATABASE"
}
. "$dir/../../retry.sh" --tries 20 "echo 'SELECT 1' | mysql"

# connect as root user, needed for expired password check
mysql_root() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint mysql \
		-e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
		"$image" \
		-hmysql \
		-uroot \
		--silent \
		"$@" \
		"$MYSQL_DATABASE" \
		2>&1
}
output=$(echo 'SELECT @@version' | mysql_root || :)

if [[ $output =~ ^5[.]5[.] ]]; then
	# 5.5 version of MySQL does not support "PASSWORD EXPIRE"
	exit 0
fi

if [[ $output =~ ^"ERROR 1862 (HY000): Your password has expired." ]]; then
	# 5.6 version shouldn't allow connection with expired password
	exit 0
fi

if [[ $output =~ ^"Please use --connect-expired-password" ]]; then
	# 5.7 version shouldn't allow connection with expired password
	exit 0
fi

echo unknown message: $output 1>&2
exit 1
