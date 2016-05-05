
FROM erlang:18

# elixir expects utf8.
ENV ELIXIR_VERSION="1.3.0-dev@574c6db" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="61173f2f545fdd9319661a31dd7be089243d09d7efd5682242170e939010c247" \
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
