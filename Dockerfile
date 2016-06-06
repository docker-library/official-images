FROM docker:1.10-git

# add "edge" since Alpine 3.3 only has Go 1.5 and we need 1.6+
RUN sed -ri -e 'p; s!^!@edge !; s!v[0-9.]+!edge!' /etc/apk/repositories

RUN apk add --no-cache \
# bash for running scripts
		bash \
# go for compiling bashbrew
		go@edge

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
