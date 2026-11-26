#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$1"
clientImage="$("$dir/../image-name.sh" librarytest/phpmyadmin-apache-run "$serverImage")"
"$dir/../docker-build.sh" "$dir" "$clientImage" <<EOF
FROM python:3.9-alpine
RUN pip install --no-cache \
		mechanize \
		pytest \
	;
COPY dir/*.py /usr/local/bin/
COPY dir/world.sql /
EOF

for dbImage in mariadb mysql; do
	dbImage="$dbImage:latest"
	# ensure the dbImage is ready and available
	if ! docker image inspect "$dbImage" &> /dev/null; then
		docker pull "$dbImage" > /dev/null
	fi
	dbPass="test-$RANDOM-password-$RANDOM-$$"

	dbCid="$(docker run -d \
		-e MYSQL_ROOT_PASSWORD="$dbPass" \
		"$dbImage")"
	trap "docker rm -vf $dbCid > /dev/null" EXIT

	# Create an instance of the container-under-test
	cid="$(docker run -d \
		--link "$dbCid":db \
		-e PMA_ARBITRARY=1 \
		"$serverImage")"
	trap "docker rm -vf $cid $dbCid > /dev/null" EXIT

	docker run -i --rm \
		--link "$cid":phpmyadmin \
		"$clientImage" \
		phpmyadmin_test.py -q --url "http://phpmyadmin/" --username "root" --password "$dbPass" db
done
