ARG ELIXIR_VERSION=1.16.2
ARG ERLANG_VERSION=26.2.2
ARG ALPINE_VERSION=3.19.1

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS build

# install build dependencies
RUN apk add --no-cache --update git build-base nodejs yarn bash openssl libstdc++

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=dev

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY test/fixtures/private.pem test/fixtures/private.pem
RUN mix deps.get
RUN mix deps.compile

# build assets
COPY assets assets
RUN cd assets && yarn install && yarn run webpack --mode production
RUN mix phx.digest

# build project
COPY priv priv
COPY lib lib
RUN mix compile

RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
EXPOSE 4000
ENTRYPOINT ["bash", "-c", "mix local.hex --force && mix do ecto.create, ecto.migrate && mix phx.server"]
