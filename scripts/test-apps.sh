#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

APPS=(elysia hono express fetch ws)
PLATFORM="${PLATFORM:-linux/amd64}"

results=()

for app in "${APPS[@]}"; do
  name="bun-test-$app"
  tag="bun-nano-test:$app"
  port=$(( 30200 + RANDOM % 1000 ))

  echo "=============================="
  echo "=== BUILD $app ==="
  echo "=============================="
  if ! docker build --platform="$PLATFORM" \
      --build-arg "APP=$app" \
      -f dockerfiles/Dockerfile.test \
      -t "$tag" . 2>&1; then
    results+=("BUILD-FAIL  $app")
    echo "  BUILD FAILED"
    continue
  fi

  size=$(docker image inspect "$tag" --format '{{.Size}}')
  human=$(numfmt --to=iec "$size" 2>/dev/null || echo "${size} bytes")

  echo "=============================="
  echo "=== TEST $app (port $port, size $human) ==="
  echo "=============================="
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --rm --platform="$PLATFORM" \
    --name "$name" -p "$port:3000" "$tag"

  # wait for server
  ok=""
  for _ in $(seq 1 75); do
    if curl -fsS --max-time 1 "http://127.0.0.1:$port/" >/dev/null 2>&1; then
      ok="yes"; break
    fi
    sleep 0.2
  done

  if [[ "$ok" != "yes" ]]; then
    echo "  STARTUP FAILED — logs:"
    docker logs "$name" 2>&1 | sed 's/^/    /' || true
    results+=("START-FAIL  $app  $human")
    docker rm -f "$name" >/dev/null 2>&1 || true
    continue
  fi

  # Run test curls
  pass=0
  fail=0

  run_test() {
    local desc="$1" cmd="$2"
    printf "  %-30s " "$desc"
    if output=$(eval "$cmd" 2>&1); then
      echo "OK  $output"
      pass=$((pass + 1))
    else
      echo "FAIL  $output"
      fail=$((fail + 1))
    fi
  }

  run_test "GET /" "curl -fsS http://127.0.0.1:$port/"
  run_test "GET /users/42" "curl -fsS http://127.0.0.1:$port/users/42"
  run_test "POST /echo" "curl -fsS -X POST -H 'Content-Type: application/json' -d '{\"x\":1}' http://127.0.0.1:$port/echo"

  # app-specific tests
  case "$app" in
    fetch)
      run_test "GET /ip (HTTPS)" "curl -fsS --max-time 10 http://127.0.0.1:$port/ip"
      run_test "GET /joke (HTTPS)" "curl -fsS --max-time 10 http://127.0.0.1:$port/joke"
      ;;
    ws)
      run_test "GET /log" "curl -fsS http://127.0.0.1:$port/log"
      ;;
  esac

  if [[ $fail -eq 0 ]]; then
    results+=("OK          $app  $human  ($pass/$pass tests)")
  else
    results+=("PARTIAL     $app  $human  ($pass/$((pass+fail)) tests)")
  fi

  docker rm -f "$name" >/dev/null 2>&1 || true
done

echo
echo "=============================="
echo "=== SUMMARY ==="
echo "=============================="
printf '%s\n' "${results[@]}"
