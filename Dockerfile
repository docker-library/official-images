# FYI, this base image is built via test-pr.sh (from https://github.com/docker-library/bashbrew/tree/master/Dockerfile)
FROM oisupport/bashbrew:base

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# wget for downloading files (especially in tests, which run in this environment)
		ca-certificates \
		wget \
# git for cloning source code
		git \
	; \
	rm -rf /var/lib/apt/lists/*

ENV DIR /usr/src/official-images
ENV BASHBREW_LIBRARY $DIR/library

WORKDIR $DIR
COPY . $DIR
