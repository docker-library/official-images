#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

serverImage="$("$dir/../image-name.sh" librarytest/mysql-check-config "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
RUN printf '[mysqld]\nmax_allowed_packet=false\n' >> \$(ls -d /etc/my.cnf.d /etc/mysql/conf.d | head -1)/99-broken.cnf
EOD

export MYSQL_ROOT_PASSWORD='this is an example test password'

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ROOT_PASSWORD \
		--name "$cname" \
		"$serverImage"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

. "$dir/../../retry.sh" \
	--tries 20 \
	--fail-expected 'ERROR: mysqld failed while attempting to check config' \
	'false'
