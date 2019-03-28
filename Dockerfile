FROM tianon/docker-tianon

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# wget for downloading files (especially in tests, which run in this environment)
		ca-certificates \
		wget \
# git for cloning source code
		git \
	; \
# go for compiling bashbrew (backports to get new enough version and to make it work on s390x)
	suite="$(awk '$1 == "deb" && $4 == "main" && $3 !~ /[\/-]/ { print $3; exit }' /etc/apt/sources.list)"; \
	echo "deb http://deb.debian.org/debian $suite-backports main" > /etc/apt/sources.list.d/backports.list; \
	apt-get update; \
	apt-get install -y --no-install-recommends -t "$suite-backports" \
		golang-go \
	; \
	rm -rf /var/lib/apt/lists/*

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

RUN set -eux; \
	CGO_ENABLED=0 ./bashbrew/bashbrew.sh --help > /dev/null; \
	cp -vL bashbrew/go/bin/bashbrew /usr/local/bin/

VOLUME $BASHBREW_CACHE

RUN ln -s "$PWD/bashbrew/bashbrew-entrypoint.sh" /usr/local/bin/bashbrew-entrypoint.sh
ENTRYPOINT ["bashbrew-entrypoint.sh"]
