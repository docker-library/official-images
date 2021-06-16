#!/bin/bash
set -eo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

cliFlags=( -h redis )

testDir="$(readlink -f "$(dirname "$BASH_SOURCE")")"
testName="$(basename "$testDir")"
if [[ "$testName" == *tls* ]]; then
	redisCliHelp="$(docker run --rm --entrypoint redis-cli "$image" --help 2>&1 || :)"
	if ! grep -q -- '--tls' <<<"$redisCliHelp"; then
		echo >&2 "skipping; not built with TLS support (possibly version < 6.0 or 32bit variant)"
		exit 0
	fi

	tlsImage="$("$testDir/../image-name.sh" librarytest/redis-tls "$image")"
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
				-out /certs/cert.csr -subj '/CN=redis'; \
			openssl x509 -req -in /certs/cert.csr \
				-CA /certs/ca.crt -CAkey /certs/ca-private.key -CAcreateserial \
				-out /certs/cert.crt -days $(( 365 * 30 )); \
			openssl verify -CAfile /certs/ca.crt /certs/cert.crt

		FROM $image
		COPY --from=certs --chown=redis:redis /certs /certs
		CMD [ \
			"--tls-port", "6379", "--port", "0", \
			"--tls-cert-file", "/certs/cert.crt", \
			"--tls-key-file", "/certs/private.key", \
			"--tls-ca-cert-file", "/certs/ca.crt" \
		]
	EOD
	image="$tlsImage"

	cliFlags+=(
		--tls
		--cert /certs/cert.crt
		--key /certs/private.key
		--cacert /certs/ca.crt
	)
fi

cname="redis-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" "$image")"
trap "docker rm -vf $cid > /dev/null" EXIT

redis-cli() {
	docker run --rm -i \
		--link "$cname":redis \
		--entrypoint redis-cli \
		"$image" \
		"${cliFlags[@]}" \
		"$@"
}

# http://redis.io/topics/quickstart#check-if-redis-is-working
. "$dir/../../retry.sh" --tries 20 '[ "$(redis-cli ping)" = "PONG" ]'

[ "$(redis-cli set mykey somevalue)" = 'OK' ]
[ "$(redis-cli get mykey)" = 'somevalue' ]
