# FYI, this base image is built via ".github/workflows/.bashbrew/action.yml" (from https://github.com/docker-library/bashbrew/tree/master/Dockerfile)
FROM oisupport/bashbrew:base

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
# wget for downloading files (especially in tests, which run in this environment)
		ca-certificates \
		wget \
# git for cloning source code
		git \
# gawk for diff-pr.sh
		gawk \
# tar -tf in diff-pr.sh
		bzip2 \
# jq for diff-pr.sh
		jq \
	; \
	rm -rf /var/lib/apt/lists/*

ENV DIR /usr/src/official-images
ENV BASHBREW_LIBRARY $DIR/library

# crane for diff-pr.sh
# https://gcr.io/go-containerregistry/crane:latest
# https://explore.ggcr.dev/?image=gcr.io/go-containerregistry/crane:latest
COPY --from=gcr.io/go-containerregistry/crane@sha256:d0e5cc313e7388a573bb4cfb980a935bb740c5787df7d90f7066b8e8146455ed /ko-app/crane /usr/local/bin/

WORKDIR $DIR
COPY . $DIR
