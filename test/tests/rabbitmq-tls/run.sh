#!/usr/bin/env bash
set -Eeuo pipefail

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

serverImage="$("$dir/../image-name.sh" librarytest/rabbitmq-tls-server "$1")"
"$dir/../docker-build.sh" "$dir" "$serverImage" <<EOD
FROM $1
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
		-out /certs/cert.csr -subj '/CN=lolcert'; \
	openssl x509 -req -in /certs/cert.csr \
		-CA /certs/ca.crt -CAkey /certs/ca-private.key -CAcreateserial \
		-out /certs/cert.crt -days $(( 365 * 30 )); \
	openssl verify -CAfile /certs/ca.crt /certs/cert.crt; \
	cat /certs/cert.crt /certs/private.key > /certs/combined.pem; \
	chmod 0400 /certs/combined.pem; \
	chown -R rabbitmq:rabbitmq /certs

COPY --chown=rabbitmq:rabbitmq dir/*.conf /etc/rabbitmq/
EOD

testImage="$("$dir/../image-name.sh" librarytest/rabbitmq-tls-test "$1")"
"$dir/../docker-build.sh" "$dir" "$testImage" <<'EOD'
FROM alpine:3.14
RUN apk add --no-cache bash coreutils drill openssl procps
# https://github.com/drwetter/testssl.sh/releases
ENV TESTSSL_VERSION 3.0.5
RUN set -eux; \
	wget -O testssl.tgz "https://github.com/drwetter/testssl.sh/archive/${TESTSSL_VERSION}.tar.gz"; \
	tar -xvf testssl.tgz -C /opt; \
	rm testssl.tgz; \
	ln -sv "/opt/testssl.sh-$TESTSSL_VERSION/testssl.sh" /usr/local/bin/; \
	testssl.sh --version
EOD

export ERLANG_COOKIE="rabbitmq-erlang-cookie-$RANDOM-$RANDOM"

cname="rabbitmq-container-$RANDOM-$RANDOM"
cid="$(docker run -d --name "$cname" --hostname "$cname" -e ERLANG_COOKIE "$serverImage")"
trap "docker rm -vf $cid > /dev/null" EXIT

testssl() {
	docker run -i --rm \
		--link "$cname" \
		"$testImage" \
		testssl.sh --quiet --color 0 "$@" "$cname:5671"
}
rabbitmqctl() {
	# not using '--entrypoint', since regular entrypoint does needed env setup
	docker run -i --rm \
		--link "$cname" \
		-e ERLANG_COOKIE \
		"$serverImage" \
		rabbitmqctl --node "rabbit@$cname" "$@"
}
rabbitmq-diagnostics() {
	# not using '--entrypoint', since regular entrypoint does needed env setup
	docker run -i --rm \
		--link "$cname" \
		-e ERLANG_COOKIE \
		"$serverImage" \
		rabbitmq-diagnostics --node "rabbit@$cname" "$@"
}

. "$dir/../../retry.sh" 'rabbitmq-diagnostics check_port_connectivity'

rabbitmqctl status
testssl --each-cipher
testssl --standard
#testssl --protocols # RabbitMQ still supports TLS 1.0/1.1 which are "deprecated" in testssl.sh 3.0+ (and thus fail this test)
