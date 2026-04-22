# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Claude Code skills repository**. Skills are reusable tools that extend Claude Code's capabilities. Each skill lives in its own top-level directory.

## Skill Structure

Each skill follows this convention:
- **`<skill-name>/SKILL.md`** — Required. YAML frontmatter (`name`, `description`, …) MUST start on line 1. This is the entry point Claude Code reads when invoking the skill.
- **`<skill-name>/CLAUDE.md`** — Optional. Maintainer / implementation notes kept out of the user-facing SKILL.md to reduce per-invocation token cost.
- **`<skill-name>/scripts/`** — Optional. Implementation scripts (typically bash). Scripts use `set -euo pipefail` and the `die()` pattern for error handling. Invoke scripts via `bash scripts/<name>.sh` so they work even when the executable bit did not survive deployment — but also `chmod +x` them on commit.
- **`<skill-name>/references/`** — Optional. Supporting files such as YAML templates or long-form reference documentation.

## Current Skills

- **`github-app-token`** — Generates a short-lived GitHub App installation access token, writes it to `.gh-token` under `$GH_CONFIG_DIR` (preferred) or `$AGENT_HOME` (fallback), and authenticates the `gh` CLI. Requires `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and one of `GITHUB_APP_PEM` (inline PEM) or `GITHUB_APP_PEM_FILE` (path). Depends on `openssl`, `curl`, `jq`, `gh`.
- **`hightower`** — Interacts with the Hightower AI pentest API: start scans, poll status, retrieve markdown reports. Requires `HIGHTOWER_API_URL` and `HIGHTOWER_API_TOKEN`. Documentation only — no scripts.
- **`kubernetes-reflector`** — Documents Kubernetes Reflector annotations for mirroring secrets and configmaps across namespaces. Documentation only — no scripts.
- **`minimax-image-generation`** — Generates images from MiniMax's `image-01` model via `/v1/image_generation`. Requires `MINIMAX_API_KEY`; `MINIMAX_API_BASE_URL` is optional. Depends on `curl`, `jq`, `base64`.

## Key Patterns

- Standard Unix tools only (`openssl`, `curl`, `jq`, `base64`). Any skill-specific runtime requirement (e.g. `gh`) is declared in that skill's `SKILL.md`.
- `die()` prints errors to stderr and exits non-zero.
- Scripts validate required env vars up front and fail loudly rather than defaulting to `mktemp`/`/tmp` for anything secret.

## No Build/Test/Lint System

There is no centralized build, test, or lint tooling. Each skill is self-contained.
