FROM erlang:20.0

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.6.0-dev@0125cd0" \
	LANG=C.UTF-8

RUN set -xe \
	&& ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION#*@}.tar.gz" \
	&& ELIXIR_DOWNLOAD_SHA256="acc02aabd5eb733405739cfe666b0d0dc0b74ff08c4de6f8368a0f09383dc47b" \
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
