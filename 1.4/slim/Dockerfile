
FROM erlang:19-slim

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.4.0-rc.0" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/releases/download/${ELIXIR_VERSION}/Precompiled.zip" \
	&& ELIXIR_DOWNLOAD_SHA256="9756080922820dad162c08d794eeec1f6655806bdaddeabf4dfb0ae5128363d6" \
	&& buildDeps=' \
		ca-certificates \
		curl \
		unzip \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o elixir-precompiled.zip $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256 elixir-precompiled.zip" | sha256sum -c - \
	&& unzip -d /usr/local elixir-precompiled.zip \
	&& rm elixir-precompiled.zip \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /var/lib/apt/lists/*

CMD ["iex"]
