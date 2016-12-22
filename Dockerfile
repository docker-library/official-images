FROM docker:1.10-git

RUN apk add --no-cache \
# bash for running scripts
		bash \
# go for compiling bashbrew
		go

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

ENV GB_VERSION 0.4.1
RUN set -x \
	&& mkdir -p /go/src/github.com/constabulary \
	&& cd /go/src/github.com/constabulary \
	&& wget -qO- "https://github.com/constabulary/gb/archive/v${GB_VERSION}.tar.gz" \
		| tar -xz \
	&& mv gb-* gb \
	&& cd gb \
	&& go install -v ./...

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

RUN cd bashbrew/go && gb build

VOLUME $BASHBREW_CACHE

RUN ln -s "$PWD/bashbrew/bashbrew-entrypoint.sh" /usr/local/bin/bashbrew-entrypoint.sh
ENTRYPOINT ["bashbrew-entrypoint.sh"]
