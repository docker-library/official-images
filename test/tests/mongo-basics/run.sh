#!/bin/bash
set -e

image="$1"

haveSeccomp=
if docker info --format '{{ join .SecurityOptions "\n" }}' 2>/dev/null |tac|tac| grep -q seccomp; then
	haveSeccomp=1

	# get docker default seccomp profile
	seccomp="$(wget -q -O - 'https://raw.githubusercontent.com/docker/docker/v17.03.1-ce/profiles/seccomp/default.json')"

	# make container with jq since it is not guaranteed on the host
	jqImage='librarytest/mongo-basics-jq:alpine'
	docker build -t "$jqImage" - > /dev/null <<-'EOF'
		FROM alpine:3.9

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
mongodCmdArgs=()
mongoArgs=( --host mongo )

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
testName="$(basename "$testDir")" # "mongo-basics" or "mongo-auth-basics" or "mongo-tls-auth"
if [[ "$testName" == *auth* ]]; then
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
fi
if [[ "$testName" == *tls* ]]; then
	tlsImage="$("$testDir/../image-name.sh" librarytest/mongo-tls "$image")"
	"$testDir/../docker-build.sh" "$testDir" "$tlsImage" <<-EOD
		FROM alpine:3.10 AS certs
		RUN apk add --no-cache openssl
		RUN set -eux; \
			mkdir /certs; \
			openssl genrsa -out /certs/ca-private.key 8192; \
			openssl req -new -x509 \
				-key /certs/ca-private.key \
				-out /certs/ca.crt \
				-days $(( 365 * 30 )) \
				-subj '/CN=lolca'; \
			openssl genrsa -out /certs/private.key 4096; \
			openssl req -new -key /certs/private.key \
				-out /certs/cert.csr -subj '/CN=mongo'; \
			openssl x509 -req -in /certs/cert.csr \
				-CA /certs/ca.crt -CAkey /certs/ca-private.key -CAcreateserial \
				-out /certs/cert.crt -days $(( 365 * 30 )); \
			openssl verify -CAfile /certs/ca.crt /certs/cert.crt

		FROM $image
		# gotta be :0 because percona's mongo doesn't have a mongodb group and estesp slayed tianon with https://github.com/moby/moby/pull/34263/files#diff-f157a3a45b3e5d85aadff73bff1f5a7cR170-R171
		COPY --from=certs --chown=mongodb:0 /certs /certs
		RUN cat /certs/cert.crt /certs/private.key > /certs/both.pem # yeah, what
	EOD
	image="$tlsImage"
	mongodRunArgs+=(
		--hostname mongo
	)
	# test for 4.2+ (where "s/ssl/tls/" was applied to all related options/flags)
	# see https://docs.mongodb.com/manual/tutorial/configure-ssl/#procedures-using-net-ssl-settings
	if docker run --rm "$image" mongod --help 2>&1 | grep -q -- ' --tlsMode '; then
		mongodCmdArgs+=(
			--tlsMode requireTLS
			--tlsCertificateKeyFile /certs/both.pem
		)
		mongoArgs+=(
			--tls
			--tlsCAFile /certs/ca.crt
		)
	else
		mongodCmdArgs+=(
			--sslMode requireSSL
			--sslPEMKeyFile /certs/both.pem
		)
		mongoArgs+=(
			--ssl
			--sslCAFile /certs/ca.crt
		)
	fi
fi

cid="$(docker_run_seccomp "${mongodRunArgs[@]}" "$image" "${mongodCmdArgs[@]}")"
trap "docker rm -vf $cid > /dev/null" EXIT

mongo() {
	docker_run_seccomp --rm -i --link "$cname":mongo "$image" mongo "${mongoArgs[@]}" "$@"
}

mongo_eval() {
	mongo --quiet --eval "$@"
}

. "$testDir/../../retry.sh" "mongo_eval 'quit(db.stats().ok ? 0 : 1);'"

if false; then
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
fi

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
