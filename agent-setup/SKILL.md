---
name: agent-setup
description: Validate AGENT_HOME, derive GH_CONFIG_DIR, and export both to a session dotfile for use by other skills.
---

# Agent Setup Skill

Validates the `AGENT_HOME` environment variable, derives `GH_CONFIG_DIR` as `$AGENT_HOME/.github`, and exports both to a session dotfile so that child bash sessions and skills invoked in the same session inherit them.

## Required Environment Variables

| Variable | Description |
|---|---|
| `AGENT_HOME` | The agent's home directory. Must be an absolute path. |

## Usage

```bash
bash agent-setup/scripts/setup.sh
source ~/.env
```

## Output

- `GH_CONFIG_DIR` is set to `$AGENT_HOME/.github` and exported
- A dotfile (`~/.env` inside `AGENT_HOME`) is written with `export GH_CONFIG_DIR=...` for session inheritance
