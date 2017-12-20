#!/bin/bash
set -e

image="$1"

haveSeccomp=
if docker info --format '{{ join .SecurityOptions "\n" }}' 2>/dev/null | grep -q seccomp; then
	haveSeccomp=1

	# get docker default seccomp profile
	seccomp="$(wget -q -O - 'https://raw.githubusercontent.com/docker/docker/v17.03.1-ce/profiles/seccomp/default.json')"

	# make container with jq since it is not guaranteed on the host
	jqImage='librarytest/mongo-basics-jq:alpine'
	docker build -t "$jqImage" - > /dev/null <<-'EOF'
		FROM alpine:3.5

		RUN apk add --no-cache jq

		ENTRYPOINT ["jq"]
	EOF

	# need set_mempolicy syscall to be able to do numactl for mongodb
	# if "set_mempolicy" is not in the always allowed list, add it
	extraSeccomp="$(echo "$seccomp" | docker run -i --rm "$jqImage" --tab '
		.syscalls[] |= if (
			.action == "SCMP_ACT_ALLOW"
			and .args == []
			and .comment == ""
			and .includes == {}
			and .excludes == {}
		) then (
			if ( .names | index("set_mempolicy") ) > 0 then
				.
			else (
				.names |= . + ["set_mempolicy"]
			) end
		)
		else
			.
		end
	')"
else
	echo >&2 'warning: the current Docker daemon does not appear to support seccomp'
fi

docker_run_seccomp() {
	if [ "$haveSeccomp" ]; then
		docker run --security-opt seccomp=<(echo "$extraSeccomp") "$@"
	else
		docker run "$@"
	fi
}

cname="mongo-container-$RANDOM-$RANDOM"
mongodRunArgs=( -d --name "$cname" )
mongoArgs=( --host mongo )

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
testName="$(basename "$testDir")" # "mongo-basics" or "mongo-auth-basics"
case "$testName" in
	*auth*)
		rootUser="root-$RANDOM"
		rootPass="root-$RANDOM-$RANDOM-password"
		mongodRunArgs+=(
			-e MONGO_INITDB_ROOT_USERNAME="$rootUser"
			-e MONGO_INITDB_ROOT_PASSWORD="$rootPass"
		)
		mongoArgs+=(
			--username="$rootUser"
			--password="$rootPass"
			--authenticationDatabase='admin'
		)
		;;
esac

cid="$(docker_run_seccomp "${mongodRunArgs[@]}" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

mongo() {
	docker_run_seccomp --rm -i --link "$cname":mongo "$image" mongo "${mongoArgs[@]}" "$@"
}

mongo_eval() {
	mongo --quiet --eval "$@"
}

tries=10
while ! mongo_eval 'quit(db.stats().ok ? 0 : 1);' &> /dev/null; do
	(( tries-- ))
	if [ $tries -le 0 ]; then
		echo >&2 'mongod failed to accept connections in a reasonable amount of time!'
		( set -x && docker logs "$cid" ) >&2 || true
		mongo --eval 'db.stats();' # to hopefully get a useful error message
		false
	fi
	echo >&2 -n .
	sleep 2
done

[ "$(mongo_eval 'db.test.count();')" = 0 ]
mongo_eval 'db.test.save({ _id: 1, a: 2, b: 3, c: "hello" });' > /dev/null
[ "$(mongo_eval 'db.test.count();')" = 1 ]
mongo_eval 'db.test.save({ _id: 1, a: 3, b: 4, c: "hello" });' > /dev/null
[ "$(mongo_eval 'db.test.count();')" = 1 ]
[ "$(mongo_eval 'db.test.findOne().a;')" = 3 ]

[ "$(mongo_eval 'db.test2.count();')" = 0 ]
mongo_eval 'db.test2.save({ _id: "abc" });' > /dev/null
[ "$(mongo_eval 'db.test2.count();')" = 1 ]
[ "$(mongo_eval 'db.test.count();')" = 1 ]
mongo_eval 'db.test2.drop();' > /dev/null
[ "$(mongo_eval 'db.test2.count();')" = 0 ]
[ "$(mongo_eval 'db.test.count();')" = 1 ]
[ "$(mongo_eval 'db.test.count();' database-that-does-not-exist)" = 0 ]

mongo_eval 'db.dropDatabase();' > /dev/null
[ "$(mongo_eval 'db.test.count();')" = 0 ]
