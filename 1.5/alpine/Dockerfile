FROM erlang:20-alpine

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.5.3" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/releases/download/${ELIXIR_VERSION}/Precompiled.zip" \
	&& ELIXIR_DOWNLOAD_SHA256="70972b844c12bc1a3960136d628ab4f21ca87dd5539c544ebabe41d6c9239ba9" \
	&& buildDeps=' \
		ca-certificates \
		curl \
		unzip \
	' \
	&& apk add --no-cache --virtual .build-deps $buildDeps \
	&& curl -fSL -o elixir-precompiled.zip $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256  elixir-precompiled.zip" | sha256sum -c - \
	&& unzip -d /usr/local elixir-precompiled.zip \
	&& rm elixir-precompiled.zip \
	&& apk del .build-deps

CMD ["iex"]
