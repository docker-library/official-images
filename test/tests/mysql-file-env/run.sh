#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

export MYSQL_PASSWORD='my cool mysql password'
export MYSQL_DATABASE='my cool mysql database'

serverImage="$("$dir/../image-name.sh" librarytest/mysql-file-env "$image")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $image
RUN echo '$MYSQL_PASSWORD' > /tmp/MYSQL_ROOT_PASSWORD
EOD

cname="mysql-container-$RANDOM-$RANDOM"
cid="$(
	docker run -d \
		-e MYSQL_ROOT_PASSWORD_FILE="/tmp/MYSQL_ROOT_PASSWORD" \
		-e MYSQL_DATABASE \
		--name "$cname" \
		"$serverImage"
)"
trap "docker rm -vf $cid > /dev/null" EXIT

mysql() {
	docker run --rm -i \
		--link "$cname":mysql \
		--entrypoint mysql \
		-e MYSQL_PWD="$MYSQL_PASSWORD" \
		"$image" \
		-hmysql \
		-u"root" \
		--silent \
		"$@" \
		"$MYSQL_DATABASE"
}

. "$dir/../../retry.sh" --tries 20 "echo 'SELECT 1' | mysql"
