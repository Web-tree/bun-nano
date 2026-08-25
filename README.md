# bun-nano

The smallest production-ready Bun Docker image. Multi-arch (`amd64` + `arm64`), published to Docker Hub and GitHub Container Registry.

| Variant | Image Size | Description |
|---|---|---|
| `webtreeofficial/bun-nano:latest` | **42.5 MB** | Alpine + musl Bun binary |
| `webtreeofficial/bun-nano:upx` | **29.8 MB** | Same + UPX compression (~250ms cold start) |

Compare to official `oven/bun:1`: 88.8 MB (Debian), `oven/bun:1-alpine`: 110+ MB.

## Quick Start

**Docker Hub:**

```dockerfile
FROM webtreeofficial/bun-nano:latest
COPY package.json bun.lock* ./
RUN bun install --production
COPY . .
CMD ["bun", "run", "server.ts"]
```

**GitHub Container Registry:**

```dockerfile
FROM ghcr.io/web-tree/bun-nano:latest
```

UPX variant (smallest):

```dockerfile
FROM webtreeofficial/bun-nano:upx
```

## Tags

Images follow Bun's version scheme. Available on both registries:

- `webtreeofficial/bun-nano:<tag>` (Docker Hub)
- `ghcr.io/web-tree/bun-nano:<tag>` (GHCR)

| Tag | Description |
|---|---|
| `1.3.12` | Specific Bun version |
| `1.3` | Latest patch in 1.3.x |
| `1` | Latest in 1.x |
| `latest` | Latest release |
| `1.3.12-upx` | UPX-compressed, specific version |
| `1.3-upx` | UPX-compressed, latest patch in 1.3.x |
| `upx` | UPX-compressed, latest |

## How It Works

1. Downloads the **musl** build of Bun from [GitHub releases](https://github.com/oven-sh/bun/releases) (multi-arch)
2. Runs on plain `alpine:3.21` with only `libstdc++` added
3. Non-root `bun` user (UID 1000)
4. UPX variant compresses the binary with LZMA (`--all-methods`)

## Auto-Release

Renovate tracks [oven-sh/bun releases](https://github.com/oven-sh/bun/releases) and
keeps the version pin fresh. When upstream ships a new Bun:

1. Renovate opens a PR bumping `BUN_VERSION` in **both** `Dockerfile` and `docker-bake.hcl`
2. `ci.yml` gates that PR: it confirms upstream published musl assets for `x64` **and**
   `aarch64`, builds the default and UPX variants, and asserts the running binary
   reports exactly the pinned version
3. Renovate auto-merges the PR once CI is green (majors are held for review)
4. Merging to `main` triggers `release.yml`, which builds both variants for both
   architectures, pushes to Docker Hub and GHCR, and only then creates the `v{VERSION}` tag

The version pin in `Dockerfile` is the single source of truth; `scripts/bun-version.sh`
reads it and fails loudly if it is missing, malformed, or out of step with
`docker-bake.hcl`. Because the images are built *before* the tag is created, a tag can
only exist if the images behind it exist.

Manual release: `gh workflow run release.yml` (publishes whatever `main` currently pins).

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
