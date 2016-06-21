
FROM erlang:19

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.3.0" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="66cb8448dd60397cad11ba554c2613f732192c9026468cff55e8347a5ae4004a" \
	&& curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
	&& echo "$ELIXIR_DOWNLOAD_SHA256 elixir-src.tar.gz" | sha256sum -c - \
	&& mkdir -p /usr/src/elixir-src \
	&& tar -xzf elixir-src.tar.gz -C /usr/src/elixir-src --strip-components=1 \
	&& rm elixir-src.tar.gz \
	&& cd /usr/src/elixir-src \
	&& make -j$(nproc) \
	&& make install \
	&& rm -rf /usr/src/elixir-src

CMD ["iex"]
