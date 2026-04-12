#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VARIANTS=(baseline distroless article compile-scratch compile-scratch-upx)
PLATFORM="${PLATFORM:-linux/amd64}"
EXPECTED="hello from bun-docker-nano"

results=()

for v in "${VARIANTS[@]}"; do
  name="bun-nano-verify-$v"
  echo "=== verifying $v ==="
  docker rm -f "$name" >/dev/null 2>&1 || true

  # find an unused host port
  port=$(( ( RANDOM % 20000 ) + 20000 ))

  cid=$(docker run -d --rm \
    --platform="$PLATFORM" \
    --name "$name" \
    -p "$port:3000" \
    "bun-nano:$v")

  # wait up to 15s for the server (UPX decompression under emulation is slow)
  ok=""
  body=""
  for _ in $(seq 1 75); do
    if body=$(curl -fsS --max-time 1 "http://127.0.0.1:$port/" 2>/dev/null); then
      ok="yes"; break
    fi
    sleep 0.2
  done

  if [[ "$ok" == "yes" && "$body" == *"$EXPECTED"* ]]; then
    size=$(docker image inspect "bun-nano:$v" --format '{{.Size}}')
    human=$(docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | awk -v t="bun-nano:$v" '$1==t{print $2}')
    results+=("OK   $v  $human  ($size bytes)")
    echo "  OK  body=$body"
  else
    results+=("FAIL $v")
    echo "  FAIL  body='$body'  logs:"
    docker logs "$name" 2>&1 | sed 's/^/    /' || true
  fi

  docker rm -f "$name" >/dev/null 2>&1 || true
done

echo
echo "=== results ==="
printf '%s\n' "${results[@]}"
