
FROM erlang:18-slim

# elixir expects utf8.
ENV ELIXIR_VERSION="1.3.0-dev@eede259" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA1="03b50890f1b6c32a49c30afc1f99883edd0de36e" \
	&& buildDeps=' \
		ca-certificates \
		curl \
		make \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA1 elixir-src.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/elixir-src \
	&& tar -xzf elixir-src.tar.gz -C /usr/src/elixir-src --strip-components=1 \
	&& rm elixir-src.tar.gz \
	&& cd /usr/src/elixir-src \
	&& make -j$(nproc) \
	&& make install \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& rm -rf /usr/src/elixir-src /var/lib/apt/lists/*

CMD ["iex"]
