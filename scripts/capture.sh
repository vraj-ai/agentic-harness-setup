#!/usr/bin/env bash
# =============================================================================
# agentic-harness-setup  —  capture.sh (live installs -> repo)
#
# Pulls the CURRENT live setups back into this repository so edits made
# directly in the live installs (e.g. ~/.prime/agent/agents/*.md) are not
# lost. Run this before committing if you changed the live files.
#
# Run:  ./scripts/capture.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION")"

echo "agentic-harness-setup v$VERSION — capturing live installs -> repo"

# --- OpenCode setup ----------------------------------------------------------
OPENCODE_SRC="$HOME/Work/skills/opencode"
if [ -d "$OPENCODE_SRC/agent" ]; then
  mkdir -p "$REPO_DIR/opencode/agent" "$REPO_DIR/opencode/command"
  cp -R "$OPENCODE_SRC/agent/." "$REPO_DIR/opencode/agent/"
  [ -d "$OPENCODE_SRC/command" ] && cp -R "$OPENCODE_SRC/command/." "$REPO_DIR/opencode/command/"
  echo "  [ok] $OPENCODE_SRC -> opencode/"
else
  echo "  [skip] $OPENCODE_SRC not found"
fi

# --- Prime Agent harness -----------------------------------------------------
PA_EXT_SRC="$HOME/.prime/agent/extensions/subagent"
PA_AGENTS_SRC="$HOME/.prime/agent/agents"
PA_PROMPTS_SRC="$HOME/.prime/agent/prompts"

if [ -d "$PA_EXT_SRC" ]; then
  mkdir -p "$REPO_DIR/prime-agent/extensions/subagent"
  cp -R "$PA_EXT_SRC/." "$REPO_DIR/prime-agent/extensions/subagent/"
  echo "  [ok] $PA_EXT_SRC -> prime-agent/extensions/subagent/"
fi

if [ -d "$PA_AGENTS_SRC" ]; then
  mkdir -p "$REPO_DIR/prime-agent/agents"
  cp -R "$PA_AGENTS_SRC/." "$REPO_DIR/prime-agent/agents/"
  echo "  [ok] $PA_AGENTS_SRC -> prime-agent/agents/"
fi

if [ -d "$PA_PROMPTS_SRC" ]; then
  mkdir -p "$REPO_DIR/prime-agent/prompts"
  cp -R "$PA_PROMPTS_SRC/." "$REPO_DIR/prime-agent/prompts/"
  echo "  [ok] $PA_PROMPTS_SRC -> prime-agent/prompts/"
fi

echo "Captured. Review the diff and commit a new version bump if needed."
