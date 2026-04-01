---
name: github-app-token
description: Generate a GitHub installation access token from a GitHub App PEM key, App ID, and Installation ID, write it to a per-agent file, then authenticate the gh CLI with it.
---

# GitHub App Token Skill

Generate a short-lived GitHub installation access token from a GitHub App's credentials and use it to authenticate the `gh` CLI.

## Prerequisites

The following environment variables MUST be set before invoking this skill:

| Variable | Description |
|---|---|
| `GITHUB_APP_ID` | The numeric App ID from the GitHub App settings page |
| `GITHUB_APP_INSTALLATION_ID` | The numeric Installation ID for the target org/user |
| `GITHUB_APP_PEM_FILE` | Absolute path to the GitHub App's PEM private key file |

If any variable is missing, stop and tell the user which ones are required.

Requires `openssl`, `curl`, and `jq`.

## Generate a Token

Build a JWT signed with the App's private key, then exchange it for an installation access token and write it to a file:

```bash
# Base64url helper
b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

# Build JWT (valid 10 minutes)
NOW=$(date +%s)
HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | jq -r -c .)
PAYLOAD=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$NOW" "$((NOW + 600))" "$GITHUB_APP_ID" | jq -r -c .)
SIGNED=$(printf '%s' "$HEADER" | b64enc).$(printf '%s' "$PAYLOAD" | b64enc)
SIG=$(printf '%s' "$SIGNED" | openssl dgst -binary -sha256 -sign "$GITHUB_APP_PEM_FILE" | b64enc)
JWT="${SIGNED}.${SIG}"

# Token file — unique per agent to avoid env-var collisions
GH_TOKEN_FILE="${AGENT_HOME:+${AGENT_HOME}/.gh-token}"
GH_TOKEN_FILE="${GH_TOKEN_FILE:-$(mktemp)}"

# Exchange JWT for installation token and write to file
curl -s -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens" \
  | jq -r '.token' > "$GH_TOKEN_FILE"

chmod 600 "$GH_TOKEN_FILE"
```

The token file path defaults to `$AGENT_HOME/.gh-token` (unique per agent) or a temporary file when `AGENT_HOME` is not set. This avoids env-var collisions when multiple agents generate tokens concurrently.

## Authenticate the gh CLI

Read the token from the file and log in:

```bash
gh auth login --with-token < "$GH_TOKEN_FILE"
```

To use `GH_TOKEN` in a single command without polluting the environment:

```bash
GH_TOKEN=$(cat "$GH_TOKEN_FILE") gh api user
```

## Cleanup

The installation access token expires after 1 hour. To revoke it early and remove the token file:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer $(cat "$GH_TOKEN_FILE")" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/installation/token"
rm -f "$GH_TOKEN_FILE"
```

## Security Notes

- Never log or echo the PEM key or installation token to stdout in production.
- The installation token is valid for 1 hour from generation.
- Store the PEM file with restrictive permissions (`chmod 600`) and never check it into git.
- The token file is written with mode `600` and should be cleaned up after use.
