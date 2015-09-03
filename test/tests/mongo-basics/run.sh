#!/bin/bash
set -e

image="$1"

cname="mongo-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

mongo() {
	docker run --rm -i --link "$cname":mongo --entrypoint mongo "$image" --host mongo "$@"
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
