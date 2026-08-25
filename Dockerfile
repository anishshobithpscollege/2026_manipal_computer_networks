# syntax=docker/dockerfile:1

FROM ghcr.io/typst/typst:0.15.1 AS typst

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        fontconfig \
        fonts-lmodern \
        fonts-dejavu \
        fonts-noto-core \
        fonts-firacode \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && fc-cache -f

# Vendor Typst packages into a fixed cache so compiles need no network.
# Add a package by dropping "name:version" into the list below. Include
# transitive deps: typed-dsa needs cetz, cetz needs oxifmt.
ENV XDG_CACHE_HOME=/opt/typst-cache
ARG CODLY_VERSION=1.3.0
ARG OXIFMT_VERSION=1.0.0
ARG CETZ_VERSION=0.5.2
ARG TYPED_DSA_VERSION=0.6.0
RUN set -eu; \
    for pkg in \
        "codly:${CODLY_VERSION}" \
        "oxifmt:${OXIFMT_VERSION}" \
        "cetz:${CETZ_VERSION}" \
        "typed-dsa:${TYPED_DSA_VERSION}"; \
    do \
        name="${pkg%%:*}"; ver="${pkg##*:}"; \
        dir="$XDG_CACHE_HOME/typst/packages/preview/$name/$ver"; \
        mkdir -p "$dir"; \
        curl -fsSL "https://packages.typst.org/preview/${name}-${ver}.tar.gz" \
            | tar -xz -C "$dir"; \
    done

COPY --from=typst /bin/typst /usr/local/bin/typst

WORKDIR /work

ENTRYPOINT ["typst"]
CMD ["--help"]
