FROM docker:stable-git

RUN apk add --no-cache \
# bash for running scripts
		bash \
# go for compiling bashbrew
		go libc-dev \
# ssl for downloading files
		libressl

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

ENV DIR /usr/src/official-images
ENV PATH $DIR/bashbrew/go/bin:$PATH

ENV BASHBREW_LIBRARY $DIR/library
ENV BASHBREW_CACHE /bashbrew-cache

# make sure our default cache dir exists and is writable by anyone (similar to /tmp)
RUN mkdir -p "$BASHBREW_CACHE" \
	&& chmod 1777 "$BASHBREW_CACHE"
# (this allows us to decide at runtime the exact uid/gid we'd like to run as)

WORKDIR $DIR
COPY . $DIR

RUN set -ex; \
	cd bashbrew/go; \
	export GOPATH="$PWD:$PWD/vendor"; \
	cd src; \
	go install -v ./...

VOLUME $BASHBREW_CACHE

RUN ln -s "$PWD/bashbrew/bashbrew-entrypoint.sh" /usr/local/bin/bashbrew-entrypoint.sh
ENTRYPOINT ["bashbrew-entrypoint.sh"]
