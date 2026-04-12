# bun-nano

The smallest production-ready Bun Docker image. Multi-arch (`amd64` + `arm64`), published to Docker Hub and GitHub Container Registry.

| Variant | Image Size | Description |
|---|---|---|
| `bun-nano:latest` | **42.5 MB** | Alpine + musl Bun binary |
| `bun-nano:upx` | **29.8 MB** | Same + UPX compression (~250ms cold start) |

Compare to official `oven/bun:1`: 88.8 MB (Debian), `oven/bun:1-alpine`: 110+ MB.

## Quick Start

```dockerfile
FROM ghcr.io/YOUR_USERNAME/bun-nano:latest
COPY package.json bun.lock* ./
RUN bun install --production
COPY . .
CMD ["bun", "run", "server.ts"]
```

Or use the UPX variant for the smallest possible image:

```dockerfile
FROM ghcr.io/YOUR_USERNAME/bun-nano:upx
```

## Tags

Images follow Bun's version scheme:

| Tag | Description |
|---|---|
| `bun-nano:1.3.12` | Specific Bun version |
| `bun-nano:1.3` | Latest patch in 1.3.x |
| `bun-nano:1` | Latest in 1.x |
| `bun-nano:latest` | Latest release |
| `bun-nano:1.3.12-upx` | UPX-compressed, specific version |
| `bun-nano:upx` | UPX-compressed, latest |

## How It Works

1. Downloads the **musl** build of Bun from [GitHub releases](https://github.com/oven-sh/bun/releases) (multi-arch)
2. Runs on plain `alpine:3.21` with only `libstdc++` added
3. Non-root `bun` user (UID 1000)
4. UPX variant compresses the binary with LZMA (`--all-methods`)

## Auto-Release

A daily cron job checks for new Bun releases. When a new version is detected:

1. `check-bun-release.yml` creates a git tag `v{VERSION}`
2. `release.yml` triggers, builds both variants for both architectures
3. Pushes to Docker Hub and GHCR

Manual releases: `gh workflow run release.yml -f bun_version=1.3.12`

## Framework Compatibility

Tested with real-world frameworks on the `compile-scratch` approach (see `tests/`):

| Framework | Status | Notes |
|---|---|---|
| Elysia | works | Bun-native, REST + params + JSON |
| Hono | works | Cross-runtime |
| Express 5 | works | Node.js compat layer |
| Built-in fetch | works | Outbound HTTPS (CA certs embedded) |
| WebSocket + fs | works | File I/O, WebSocket server |

### Known Limitations

- Native `.node` addons will not work (use pure-JS alternatives)
- Runtime-computed `require()` paths may silently fail with `bun build --compile`
- `import.meta.url` for asset resolution breaks in compiled binaries

## For the Absolute Smallest Image

If you use `bun build --compile`, you can skip the base image entirely and use a `scratch`-based approach. See `dockerfiles/Dockerfile.compile-scratch-upx` — this produces a **26.3 MB** image for compiled apps.

## Local Development

```bash
# Build with docker bake
docker buildx bake local --load

# Build all variants
docker buildx bake

# Test
docker run --rm bun-nano:local --version
docker run --rm bun-nano:local -e "console.log('hello')"
```

## Setup

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

`GITHUB_TOKEN` is provided automatically for GHCR.

## Credits

Inspired by [Smallest Bun Docker Image](https://blog.dejangegic.com/smallest-bun-docker-image) by Dejan Gegic.
