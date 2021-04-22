#!/bin/sh
mysql -u "${MARIADB_USER:-$MYSQL_USER}" -p"${MARIADB_PASSWORD:-$MYSQL_PASSWORD}" \
	-e 'create table t1 (i int unsigned primary key not null)' \
	"${MARIADB_DATABASE:-$MYSQL_DATABASE}"
