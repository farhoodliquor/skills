---
name: github-app-token
description: Generate a GitHub installation access token from a GitHub App PEM key, App ID, and Installation ID, then authenticate the gh CLI with it.
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

Requires `openssl`, `curl`, `grep`, and `jq` (standard on modern environments).

## Steps

### 1. Generate and Export Token

Run the helper script and `eval` its output. This securely exports the short-lived GitHub installation access token as `GH_TOKEN` into your current process environment.

**Important:** Because `eval` sets the variable in the current shell process, any commands that need `GH_TOKEN` must run in the **same shell invocation**. Chain all dependent commands together:

```bash
eval "$(/path/to/skills/github-app-token/scripts/generate_token.sh)" && gh api user
```

Do NOT run `eval` in one command and then use `GH_TOKEN` in a separate command — the variable will not persist between separate shell invocations.

> [!NOTE]
> For a CI/CD environment (like GitHub Actions), you can extract the token to pass it between steps like so:
> `echo "GH_TOKEN=$(/path/to/skills/github-app-token/scripts/generate_token.sh | cut -d'"' -f2)" >> $GITHUB_ENV`

The script will:
1. Automatically construct a short-lived authorization assertion using your App ID and PEM key
2. Call the GitHub API to securely exchange that for an Installation Access Token
3. Output the `export GH_TOKEN="..."` command to set it in your environment.

### 2. Authenticate the gh CLI

With `GH_TOKEN` set (in the same shell), the `gh` CLI operates securely and without needing a separate authentication login for most API operations. Note that `gh auth status` may not reflect the token since it checks local config, but `gh` will respect the `GH_TOKEN` environment variable.

To both generate the token and authenticate `gh` in one go:

```bash
eval "$(/path/to/skills/github-app-token/scripts/generate_token.sh)" && echo "${GH_TOKEN}" | gh auth login --with-token && gh auth status
```

### 4. Cleanup

The installation access token expires after 1 hour. There is nothing to revoke unless you want to explicitly invalidate it early:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/installation/token"
```

## Security Notes

- Never log or echo the PEM key or installation token to stdout in production.
- The installation token represents your GitHub App and is strictly valid for 1 hour from generation.
- Store the PEM file with restrictive permissions (`chmod 600`) and never check it into git.
