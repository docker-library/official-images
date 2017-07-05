FROM golang:1.8-alpine

RUN apk add --no-cache \
		file \
		gnupg \
		libressl

WORKDIR /usr/src/bashbrew
ENV GOPATH /usr/src/bashbrew:/usr/src/bashbrew/vendor
ENV CGO_ENABLED 0

# https://github.com/estesp/manifest-tool/releases
ENV MANIFEST_TOOL_VERSION 0.6.0
# gpg: key 0F386284C03A1162: public key "Philip Estes <estesp@gmail.com>" imported
ENV MANIFEST_TOOL_GPG_KEY 27F3EA268A97867EAF0BD05C0F386284C03A1162

COPY go .

RUN set -ex; \
	\
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$MANIFEST_TOOL_GPG_KEY"; \
	\
	mkdir bin; \
	for osArch in \
		amd64 \
		arm32v5 \
		arm32v6 \
		arm32v7 \
		arm64v8 \
		darwin-amd64 \
		i386 \
		ppc64le \
		s390x \
		windows-amd64 \
	; do \
		os="${osArch%%-*}"; \
		[ "$os" != "$osArch" ] || os='linux'; \
		export GOOS="$os"; \
		arch="${osArch#${os}-}"; \
		unset GOARM GO386; \
		case "$arch" in \
			arm32v*) export GOARCH='arm' GOARM="${arch#arm32v}" ;; \
# no GOARM for arm64 (yet?) -- https://github.com/golang/go/blob/1e72bf62183ea21b9affffd4450d44d994393899/src/cmd/internal/objabi/util.go#L40
			arm64v*) export GOARCH='arm64' ;; \
			i386)    export GOARCH='386' ;; \
			*)       export GOARCH="$arch" ;; \
		esac; \
		\
		[ "$os" = 'windows' ] && ext='.exe' || ext=''; \
		\
		go build \
			-a -v \
			-ldflags '-s -w' \
# see https://github.com/golang/go/issues/9737#issuecomment-276817652 (and following comments) -- installsuffix is necessary (for now) to keep ARM
# can remove "$osArch" from "installsuffix" in Go 1.10+ (https://github.com/golang/go/commit/1b53f15ebb00dd158af674df410c7941abb2b933)
			-tags netgo -installsuffix "netgo-$osArch" \
			-o "bin/bashbrew-$osArch$ext" \
			./src/bashbrew; \
		\
		case "$GOARCH" in \
# manifest-tool and GOARM aren't friends yet
# ... and estesp is probably a big fat "lololol" on supporting i386 :D
			arm|386) continue ;; \
		esac; \
		wget -O "bin/manifest-tool-$osArch$ext" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-$GOOS-$GOARCH$ext"; \
		wget -O "bin/manifest-tool-$osArch$ext.asc" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-$GOOS-$GOARCH$ext.asc"; \
		gpg --batch --verify "bin/manifest-tool-$osArch$ext.asc" "bin/manifest-tool-$osArch$ext"; \
	done; \
	\
	rm -rf "$GNUPGHOME"; \
	\
	ls -l bin; \
	file bin/*
