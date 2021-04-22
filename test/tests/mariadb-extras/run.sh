#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"


killoff()
{
	[ -n "$cid" ] && docker kill $cid > /dev/null
	sleep 2
	[ -n "$cid" ] && docker rm -vif $cid > /dev/null
	cid=""
}

die()
{
	[ -n "$cid" ] && docker logs $cid
	killoff
        echo $@ >&2
        exit 1
}
trap "killoff" EXIT

runandwait()
{
	cname="mariadb-container-$RANDOM-$RANDOM"
	cid="$(
		docker run -d \
			--name "$cname" --rm --publish 3306 "$@"
	)"
	port=$(docker port "$cname" 3306)
	port=${port#*:}

	waiting=10
	echo "waiting to start..."
	set +e +o pipefail +x
	while [ $waiting -gt 0 ]
	do
		(( waiting-- ))
		sleep 1
		if ! docker exec -ti $cid mysql -h localhost --protocol tcp -P 3306 -e 'select 1' 2>&1 | fgrep "Can't connect" > /dev/null
		then
			break
		fi
        done
	set -eo pipefail -x
	if [ $waiting -eq 0 ]
	then
		die 'timeout'
	fi
}

mariadbclient() {
	docker exec -ti \
		"$cname" \
		mysql \
		--host 127.0.0.1 \
		--protocol tcp \
		--silent \
		"$@"
}

mariadbclient_unix() {
	docker exec -ti \
		"$cname" \
		mysql \
		--silent \
		"$@"
}

echo -e "Test: expect Failure - none of MYSQL_ALLOW_EMPTY_PASSWORD, MYSQL_RANDOM_ROOT_PASSWORD, MYSQL_ROOT_PASSWORD\n"

cname="mariadb-container-fail-to-start-options-$RANDOM-$RANDOM"
docker run --name "$cname" --rm "$image" && die "$cname should fail with unspecified option"

echo -e "Test: MYSQL_ALLOW_EMPTY_PASSWORD Implementation is non-empty value so this should fail\n"
docker run  --rm  --name "$cname" -e MYSQL_ALLOW_EMPTY_PASSWORD  "$image" || echo 'expected failure of empty MYSQL_ALLOW_EMPTY_PASSWORD'

echo -e "Test: MYSQL_ALLOW_EMPTY_PASSWORD and defaults to clean environment\n"

runandwait -e MYSQL_ALLOW_EMPTY_PASSWORD=1 "${image}"
mariadbclient -u root -e 'show databases'

othertables=$(mariadbclient -u root --skip-column-names -Be "select group_concat(SCHEMA_NAME) from information_schema.SCHEMATA where SCHEMA_NAME not in ('mysql', 'information_schema', 'performance_schema', 'sys')")
[ "${othertables}" != $'NULL\r' ] && die "unexpected table(s) $othertables"

otherusers=$(mariadbclient -u root --skip-column-names -Be "select user,host from mysql.user where (user,host) not in (('root', 'localhost'), ('root', '%'), ('mariadb.sys', 'localhost'))")
[ "$otherusers" != '' ] && die "unexpected users $otherusers"
killoff

echo -e "Test: MYSQL_ROOT_PASSWORD\n"

runandwait -e MYSQL_ROOT_PASSWORD=examplepass "${image}"
mariadbclient -u root -pexamplepass -e 'select current_user()'
mariadbclient -u root -pwrongpass -e 'select current_user()' || echo 'expected failure' 
killoff 

echo -e "Test: MYSQL_RANDOM_ROOT_PASSWORD, needs to satisify minimium complexity of simple-password-check plugin\n"

runandwait -e MYSQL_RANDOM_ROOT_PASSWORD=1 "${image}" --plugin-load-add=simple_password_check
pass=$(docker logs $cid | grep 'GENERATED ROOT PASSWORD' 2>&1)
# trim up until passwod
pass=${pass#*GENERATED ROOT PASSWORD: }
mariadbclient -u root -p"${pass}" -e 'select current_user()'
killoff

echo -e "Test: second instance of MYSQL_RANDOM_ROOT_PASSWORD has a differnet password\n"

runandwait -e MYSQL_RANDOM_ROOT_PASSWORD=1  "${image}" --plugin-load-add=simple_password_check
newpass=$(docker logs $cid | grep 'GENERATED ROOT PASSWORD' 2>&1)
# trim up until passwod
newpass=${newpass#*GENERATED ROOT PASSWORD: }
mariadbclient -u root -p"${newpass}" -e 'select current_user()'
killoff

[ "$pass" = "$newpass" ] && die "highly improbable - two consequitive passwords are the same"

echo -e "Test: MYSQL_ROOT_HOST\n"

runandwait -e  MYSQL_ALLOW_EMPTY_PASSWORD=1  -e MYSQL_ROOT_HOST=apple "${image}" 
ru=$(mariadbclient_unix --skip-column-names -B -u root -e 'select user,host from mysql.user where host="apple"')
[ "${ru}" = '' ] && die 'root@apple not created'
killoff

echo -e "Test: complex passwords\n"

runandwait -e MYSQL_USER=bob -e MYSQL_PASSWORD=$' \' ' -e MYSQL_ROOT_PASSWORD=$'\'\\aa-\x00-zz"_%' "${image}"
mariadbclient_unix --skip-column-names -B -u root -p$'\'\\aa-\x00-zz"_%' -e 'select 1'
mariadbclient_unix --skip-column-names -B -u bob -p$' \' ' -e 'select 1'
killoff

echo -e "Test: MYSQL_INITDB_SKIP_TZINFO='' should still load timezones\n"

runandwait -e MYSQL_INITDB_SKIP_TZINFO= -e MYSQL_ALLOW_EMPTY_PASSWORD=1 "${image}" 
tzcount=$(mariadbclient --skip-column-names -B -u root -e "SELECT COUNT(*) FROM mysql.time_zone")
[ "${tzcount}" = $'0\r' ] && die "should exist timezones"
killoff

echo -e "Test: MYSQL_INITDB_SKIP_TZINFO=1 should not load timezones\n"

runandwait -e MYSQL_INITDB_SKIP_TZINFO=1 -e MYSQL_ALLOW_EMPTY_PASSWORD=1 "${image}" 
tzcount=$(mariadbclient --skip-column-names -B -u root -e "SELECT COUNT(*) FROM mysql.time_zone")
[ "${tzcount}" = $'0\r' ] || die "timezones shouldn't be loaded - found ${tzcount}"
killoff

echo -e "Test: Secrets _FILE vars shoud be same as env directly\n"

secretdir=$(mktemp -d)
chmod go+rx "${secretdir}"
echo bob > "$secretdir"/pass
echo pluto > "$secretdir"/host
echo titan > "$secretdir"/db
echo ron > "$secretdir"/u
echo scappers > $secretdir/p

runandwait \
       	-v "$secretdir":/run/secrets:Z \
	-e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/pass \
	-e MYSQL_ROOT_HOST_FILE=/run/secrets/host \
	-e MYSQL_DATABASE_FILE=/run/secrets/db \
	-e MYSQL_USER_FILE=/run/secrets/u \
	-e MYSQL_PASSWORD_FILE=/run/secrets/p \
	"${image}" 

host=$(mariadbclient_unix --skip-column-names -B -u root -pbob -e 'select host from mysql.user where user="root" and host="pluto"' titan)
[ "${host}" != $'pluto\r' ] && die 'root@pluto not created'
creation=$(mariadbclient --skip-column-names -B -u ron -pscappers -P 3306 --protocol tcp titan -e "CREATE TABLE landing(i INT)")
[ "${creation}" = '' ] || die 'creation error'
killoff
rm -rf "${secretdir}"

echo -e "Test: docker-entrypoint-initdb.d Initialization order is correct and processed\n"

initdb=$(mktemp -d)
chmod go+rx "${initdb}"
cp -a initdb.d/* "${initdb}"
gzip "${initdb}"/*gz*
xz "${initdb}"/*xz*
zstd "${initdb}"/*zst*

runandwait \
        -v "${initdb}":/docker-entrypoint-initdb.d:Z \
	-e MYSQL_ROOT_PASSWORD=ssh \
	-e MYSQL_DATABASE=titan \
	-e MYSQL_USER=ron \
	-e MYSQL_PASSWORD=scappers \
	"${image}" 

init_sum=$(mariadbclient --skip-column-names -B -u ron -pscappers -P 3306 -h 127.0.0.1  --protocol tcp titan -e "select sum(i) from t1;")
[ "${init_sum}" = $'1833\r' ] || (podman logs m_init; die 'initialization order error')
killoff
rm -rf "${initdb}"


echo -e "Test: when provided with MYSQL_ and MARIADB_ names, Prefer MariaDB names\n"

runandwait -e MARIADB_ROOT_PASSWORD=examplepass -e MYSQL_ROOT_PASSWORD=mysqlexamplepass "${image}"
mariadbclient -u root -pexamplepass -e 'select current_user()'
mariadbclient -u root -pwrongpass -e 'select current_user()' || echo 'expected failure of wrong password'
killoff

echo -e "Test: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD Implementation is non-empty value so this should fail\n"

docker run  --rm  --name "$cname" -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD "$image" || echo 'expected failure MARIADB_ALLOW_EMPTY_ROOT_PASSWORD is empty'

echo -e "Test: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD\n"

# +Defaults to clean environment
runandwait -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 "${image}"
mariadbclient -u root -e 'show databases'

othertables=$(mariadbclient -u root --skip-column-names -Be "select group_concat(SCHEMA_NAME) from information_schema.SCHEMATA where SCHEMA_NAME not in ('mysql', 'information_schema', 'performance_schema', 'sys')")
[ "${othertables}" != $'NULL\r' ] && die "unexpected table(s) $othertables"

otherusers=$(mariadbclient -u root --skip-column-names -Be "select user,host from mysql.user where (user,host) not in (('root', 'localhost'), ('root', '%'), ('mariadb.sys', 'localhost'))")
[ "$otherusers" != '' ] && die "unexpected users $otherusers"
killoff

echo -e "Test: MARIADB_ROOT_PASSWORD\n"

runandwait -e MARIADB_ROOT_PASSWORD=examplepass "${image}"
mariadbclient -u root -pexamplepass -e 'select current_user()'
mariadbclient -u root -pwrongpass -e 'select current_user()' || echo 'expected failure' 
killoff 

echo -e "Test: MARIADB_RANDOM_ROOT_PASSWORD, needs to satisify minimium complexity of simple-password-check plugin\n"

runandwait -e MARIADB_RANDOM_ROOT_PASSWORD=1 "${image}" --plugin-load-add=simple_password_check
pass=$(docker logs $cid  2>&1 | grep 'GENERATED ROOT PASSWORD')
# trim up until passwod
pass=${pass#*GENERATED ROOT PASSWORD: }
mariadbclient -u root -p"${pass}" -e 'select current_user()'
killoff

echo -e "Test: second instance of MARIADB_RANDOM_ROOT_PASSWORD has a differnet password\n"

runandwait -e MARIADB_RANDOM_ROOT_PASSWORD=1 "${image}" --plugin-load-add=simple_password_check
newpass=$(docker logs $cid  2>&1 | grep 'GENERATED ROOT PASSWORD')
# trim up until passwod
newpass=${newpass#*GENERATED ROOT PASSWORD: }
mariadbclient -u root -p"${newpass}" -e 'select current_user()'
killoff

[ "$pass" = "$newpass" ] && die "highly improbable - two consequitive random passwords are the same"

echo -e "Test: MARIADB_ROOT_HOST\n"

runandwait -e  MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1  -e MARIADB_ROOT_HOST=apple "${image}"
ru=$(mariadbclient_unix --skip-column-names -B -u root -e 'select user,host from mysql.user where host="apple"')
[ "${ru}" = '' ] && die 'root@apple not created'
killoff

echo -e "Test: MARIADB_INITDB_SKIP_TZINFO=''\n"

runandwait -e MARIADB_INITDB_SKIP_TZINFO= -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 "${image}"
tzcount=$(mariadbclient --skip-column-names -B -u root -e "SELECT COUNT(*) FROM mysql.time_zone")
[ "${tzcount}" = $'0\r' ] && die "should exist timezones"
killoff

echo -e "Test: MARIADB_INITDB_SKIP_TZINFO=1\n"

runandwait -e MARIADB_INITDB_SKIP_TZINFO=1 -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 "${image}"
tzcount=$(mariadbclient --skip-column-names -B -u root -e "SELECT COUNT(*) FROM mysql.time_zone")
[ "${tzcount}" = $'0\r' ] || die "timezones shouldn't be loaded - found ${tzcount}"
killoff

# lazy test because ubuntu arch isn't always the same as uname -m
if [ $(uname -m) = 'x86_64' ]
then
	echo -e "Test: jemalloc preload\n"
	runandwait -e LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libjemalloc.so.1 /usr/lib/x86_64-linux-gnu/libjemalloc.so.2" -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 "${image}"
	docker exec -ti $cid gosu mysql /bin/grep 'jemalloc' /proc/1/maps || die "expected to preload jemalloc"
	killoff
fi

