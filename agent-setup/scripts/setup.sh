#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -z "${AGENT_HOME:-}" ]] && die "AGENT_HOME is not set"

# Derive GH_CONFIG_DIR — gh stores config at ~/.config/gh by default,
# so we mirror that structure under AGENT_HOME
export GH_CONFIG_DIR="$AGENT_HOME/.github"

# Write to a session dotfile so child processes inherit the variables
mkdir -p "$AGENT_HOME"
cat > "$AGENT_HOME/.env" <<EOF
export GH_CONFIG_DIR="$GH_CONFIG_DIR"
EOF

echo "GH_CONFIG_DIR set to $GH_CONFIG_DIR"
