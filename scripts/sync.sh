#!/usr/bin/env bash
# =============================================================================
# agentic-harness-setup  —  sync.sh (repo -> live installs)
#
# Deploys the versioned harness from this repository into the live agent
# setups on this machine:
#
#   opencode/       -> ~/Work/skills/opencode        (OpenCode agent setup)
#   prime-agent/    -> ~/.prime/agent                (Prime Agent harness)
#
# Run:  ./scripts/sync.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION")"

echo "agentic-harness-setup v$VERSION — syncing repo -> live installs"

# --- OpenCode setup (skills) ------------------------------------------------
OPENCODE_DEST="$HOME/Work/skills/opencode"
if [ -d "$REPO_DIR/opencode" ]; then
  mkdir -p "$OPENCODE_DEST"
  cp -R "$REPO_DIR/opencode/." "$OPENCODE_DEST/"
  echo "  [ok] opencode/ -> $OPENCODE_DEST"
else
  echo "  [skip] no opencode/ in repo"
fi

# --- Prime Agent harness -----------------------------------------------------
PA_EXT_DEST="$HOME/.prime/agent/extensions/subagent"
PA_AGENTS_DEST="$HOME/.prime/agent/agents"
PA_PROMPTS_DEST="$HOME/.prime/agent/prompts"

if [ -d "$REPO_DIR/prime-agent/extensions/subagent" ]; then
  mkdir -p "$PA_EXT_DEST"
  cp -R "$REPO_DIR/prime-agent/extensions/subagent/." "$PA_EXT_DEST/"
  echo "  [ok] prime-agent/extensions/subagent -> $PA_EXT_DEST"
else
  echo "  [skip] no prime-agent/extensions/subagent in repo"
fi

if [ -d "$REPO_DIR/prime-agent/agents" ]; then
  mkdir -p "$PA_AGENTS_DEST"
  cp -R "$REPO_DIR/prime-agent/agents/." "$PA_AGENTS_DEST/"
  echo "  [ok] prime-agent/agents -> $PA_AGENTS_DEST"
else
  echo "  [skip] no prime-agent/agents in repo"
fi

if [ -d "$REPO_DIR/prime-agent/prompts" ]; then
  mkdir -p "$PA_PROMPTS_DEST"
  cp -R "$REPO_DIR/prime-agent/prompts/." "$PA_PROMPTS_DEST/"
  echo "  [ok] prime-agent/prompts -> $PA_PROMPTS_DEST"
else
  echo "  [skip] no prime-agent/prompts in repo"
fi

echo "Done (v$VERSION). Restart or run '/reload' in prime-agent to pick up changes."
