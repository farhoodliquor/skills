#!/usr/bin/env bash
# Generate a JWT for GitHub App authentication.
#
# Required environment variables:
#   GITHUB_APP_ID       - The GitHub App's numeric ID
#   GITHUB_APP_PEM_FILE - Path to the PEM-encoded private key file
#
# Prints the signed JWT to stdout.

set -euo pipefail

if [[ -z "${GITHUB_APP_ID:-}" ]]; then
  echo "error: GITHUB_APP_ID is not set" >&2
  exit 1
fi

if [[ -z "${GITHUB_APP_PEM_FILE:-}" ]]; then
  echo "error: GITHUB_APP_PEM_FILE is not set" >&2
  exit 1
fi

if [[ ! -f "${GITHUB_APP_PEM_FILE}" ]]; then
  echo "error: PEM file not found: ${GITHUB_APP_PEM_FILE}" >&2
  exit 1
fi

## Build JWT

header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

now=$(date +%s)
iat=$((now - 60))
exp=$((now + 600))

payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$iat" "$exp" "$GITHUB_APP_ID" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

unsigned="${header}.${payload}"

signature=$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "${GITHUB_APP_PEM_FILE}" -binary | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

echo "${unsigned}.${signature}"
