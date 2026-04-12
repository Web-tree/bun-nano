#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VARIANTS=(baseline distroless article compile-scratch compile-scratch-upx)
PLATFORM="${PLATFORM:-linux/amd64}"

for v in "${VARIANTS[@]}"; do
  echo "=== building $v ==="
  docker build \
    --platform="$PLATFORM" \
    -f "dockerfiles/Dockerfile.$v" \
    -t "bun-nano:$v" \
    .
done

echo
echo "=== sizes ==="
docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | grep '^bun-nano:' | sort
