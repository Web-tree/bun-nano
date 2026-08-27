ARG BUN_VERSION=1.4.0
ARG ALPINE_VERSION=3.24

# ---------------------------------------------------------------------------
# Stage 1: download the musl build of Bun for the target architecture
# ---------------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS download
ARG BUN_VERSION
ARG TARGETARCH

RUN apk add --no-cache curl unzip && \
    ARCH=$([ "$TARGETARCH" = "amd64" ] && echo "x64" || echo "aarch64") && \
    curl -fsSL \
      "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-${ARCH}-musl.zip" \
      -o /tmp/bun.zip && \
    unzip /tmp/bun.zip -d /tmp && \
    mv /tmp/bun-linux-*/bun /usr/local/bin/bun && \
    chmod +x /usr/local/bin/bun

# ---------------------------------------------------------------------------
# Stage 2 (optional): UPX-compress the binary
# ---------------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS compress
RUN apk add --no-cache upx
COPY --from=download /usr/local/bin/bun /usr/local/bin/bun
RUN upx --all-methods /usr/local/bin/bun

# ---------------------------------------------------------------------------
# Final: default variant — plain bun binary on Alpine + libstdc++
# ---------------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS default
RUN apk add --no-cache libstdc++ && \
    addgroup -g 1000 bun && \
    adduser -u 1000 -G bun -s /bin/sh -D bun && \
    mkdir -p /app && chown bun:bun /app
COPY --from=download /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx
USER bun
WORKDIR /app
ENTRYPOINT ["bun"]

# ---------------------------------------------------------------------------
# Final: UPX variant — compressed bun binary on Alpine + libstdc++
# ---------------------------------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS upx
RUN apk add --no-cache libstdc++ && \
    addgroup -g 1000 bun && \
    adduser -u 1000 -G bun -s /bin/sh -D bun && \
    mkdir -p /app && chown bun:bun /app
COPY --from=compress /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx
USER bun
WORKDIR /app
ENTRYPOINT ["bun"]
