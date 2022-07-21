#!/bin/bash
set -e

image="$1"

cname="mongo-container-$RANDOM-$RANDOM"
mongodRunArgs=( -d --name "$cname" --cap-add SYS_NICE ) # SYS_NICE is for NUMA (needed for MongoDB 3.6 on NUMA-enabled hosts)
mongodCmdArgs=()

mongo='mongo'
mongoArgs=( --host mongo )
countFunc='function count(coll) { return coll.count() }' # count(db.test)
upsertFunc='function upsert(coll, doc) { return coll.save(doc) }' # upsert(db.test, { _id: 'foo', bar: 'baz' })
if docker run --rm --entrypoint sh "$image" -c 'command -v mongosh > /dev/null'; then
	mongo='mongosh'
	# https://www.mongodb.com/docs/mongodb-shell/reference/compatibility/#std-label-compatibility
	countFunc='function count(coll) { return coll.countDocuments() }' # https://www.mongodb.com/docs/manual/reference/method/db.collection.countDocuments/
	upsertFunc='function upsert(coll, doc) { return coll.initializeUnorderedBulkOp().find({ _id: doc._id }).upsert().replaceOne(doc).execute() }' # https://www.mongodb.com/docs/manual/reference/method/Bulk.find.upsert/#insert-for-bulk.find.replaceone--
fi

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
		FROM alpine:3.14 AS certs
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

cid="$(docker run "${mongodRunArgs[@]}" "$image" "${mongodCmdArgs[@]}")"
trap "docker rm -vf $cid > /dev/null" EXIT

mongo() {
	docker run --rm -i --cap-add SYS_NICE \
		--link "$cname":mongo \
		--entrypoint "$mongo" \
		"$image" \
		"${mongoArgs[@]}" "$@"
}

mongo_eval() {
	local eval="$1"; shift
	mongo --quiet --eval "$countFunc; $upsertFunc; $eval" "$@"
}
mongo_eval_67788() {
	# workaround for https://jira.mongodb.org/browse/SERVER-67788
	local -
	shopt -s extglob
	local out
	out="$(mongo_eval "$@")"
	echo "${out##+([^0-9]*$'\n')}"
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

[ "$(mongo_eval_67788 'count(db.test);')" = 0 ]
mongo_eval 'upsert(db.test, { _id: 1, a: 2, b: 3, c: "hello" });' > /dev/null
[ "$(mongo_eval_67788 'count(db.test);')" = 1 ]
mongo_eval 'upsert(db.test, { _id: 1, a: 3, b: 4, c: "hello" });' > /dev/null
[ "$(mongo_eval_67788 'count(db.test);')" = 1 ]
[ "$(mongo_eval_67788 'db.test.findOne().a;')" = 3 ]

[ "$(mongo_eval_67788 'count(db.test2);')" = 0 ]
mongo_eval 'upsert(db.test2, { _id: "abc" });' > /dev/null
[ "$(mongo_eval_67788 'count(db.test2);')" = 1 ]
[ "$(mongo_eval_67788 'count(db.test);')" = 1 ]
mongo_eval 'db.test2.drop();' > /dev/null
[ "$(mongo_eval_67788 'count(db.test2);')" = 0 ]
[ "$(mongo_eval_67788 'count(db.test);')" = 1 ]
[ "$(mongo_eval_67788 'count(db.test);' database-that-does-not-exist)" = 0 ]

mongo_eval 'db.dropDatabase();' > /dev/null
[ "$(mongo_eval_67788 'count(db.test);')" = 0 ]
