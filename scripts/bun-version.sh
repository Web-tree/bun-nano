#!/usr/bin/env bash
# Single source of truth for "which Bun does this repo pin?".
#
# CI and Release both read the version through this script so the parse and its
# guards exist exactly once. The guards matter: the previous release pipeline
# derived the version from a `curl | jq | sed` pipeline whose exit status was
# sed's, so a rate-limited curl silently produced an empty string and the job
# tagged the repo `v` (with no version at all). Anything that can't produce a
# real x.y.z version must fail loudly here instead of being published.
set -euo pipefail

cd "$(dirname "$0")/.."

dockerfile_version=$(sed -n 's/^ARG BUN_VERSION=\([^[:space:]]*\).*/\1/p' Dockerfile | head -n1)
bake_version=$(sed -n '/^variable "BUN_VERSION"/,/^}/s/.*default *= *"\([^"]*\)".*/\1/p' docker-bake.hcl | head -n1)

if [[ -z "$dockerfile_version" ]]; then
  echo "ERROR: no 'ARG BUN_VERSION=' line found in Dockerfile" >&2
  exit 1
fi

if [[ ! "$dockerfile_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: Dockerfile pins BUN_VERSION='${dockerfile_version}', which is not an x.y.z version" >&2
  exit 1
fi

# Renovate bumps both files in one PR. If they ever diverge, bake would build a
# different Bun than the Dockerfile claims and the published tags would lie.
if [[ "$dockerfile_version" != "$bake_version" ]]; then
  echo "ERROR: version pins disagree — Dockerfile has '${dockerfile_version}', docker-bake.hcl has '${bake_version}'" >&2
  echo "       Both must move together; see the BUN_VERSION customManager in renovate.json." >&2
  exit 1
fi

echo "$dockerfile_version"
