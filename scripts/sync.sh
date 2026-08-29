#!/usr/bin/env bash
# agentic-harness-setup — sync.sh (repo -> live installs)
#
#   opencode/  -> ~/.config/opencode
#   omp/       -> ~/.omp/agent/agents
#   prime-agent/ -> ~/.prime/agent
#
# Also mirrors OpenCode templates into ~/Work/skills/harness/opencode when
# that skills clone exists, so the two repos do not drift.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION")"

echo "agentic-harness-setup v$VERSION — syncing repo -> live installs"

OPENCODE_LIVE="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
if [ -d "$REPO_DIR/opencode" ]; then
  mkdir -p "$OPENCODE_LIVE/agent" "$OPENCODE_LIVE/command"
  cp -R "$REPO_DIR/opencode/agent/." "$OPENCODE_LIVE/agent/"
  [ -d "$REPO_DIR/opencode/command" ] && cp -R "$REPO_DIR/opencode/command/." "$OPENCODE_LIVE/command/"
  echo "  [ok] opencode/ -> $OPENCODE_LIVE"
  SKILLS_OC="$HOME/Work/skills/harness/opencode"
  if [ -d "$HOME/Work/skills/harness" ]; then
    mkdir -p "$SKILLS_OC/agent" "$SKILLS_OC/command"
    cp -R "$REPO_DIR/opencode/agent/." "$SKILLS_OC/agent/"
    [ -d "$REPO_DIR/opencode/command" ] && cp -R "$REPO_DIR/opencode/command/." "$SKILLS_OC/command/"
    echo "  [ok] opencode/ -> $SKILLS_OC"
  fi
else
  echo "  [skip] no opencode/ in repo"
fi

OMP_LIVE="${OMP_AGENTS_DIR:-$HOME/.omp/agent/agents}"
if [ -d "$REPO_DIR/omp/agent" ]; then
  mkdir -p "$OMP_LIVE"
  cp -R "$REPO_DIR/omp/agent/." "$OMP_LIVE/"
  echo "  [ok] omp/agent -> $OMP_LIVE"
  SKILLS_OMP="$HOME/Work/skills/harness/omp/agent"
  if [ -d "$HOME/Work/skills/harness" ]; then
    mkdir -p "$SKILLS_OMP"
    cp -R "$REPO_DIR/omp/agent/." "$SKILLS_OMP/"
    echo "  [ok] omp/agent -> $SKILLS_OMP"
  fi
else
  echo "  [skip] no omp/agent in repo"
fi

PA_EXT_DEST="$HOME/.prime/agent/extensions/subagent"
PA_AGENTS_DEST="$HOME/.prime/agent/agents"
PA_PROMPTS_DEST="$HOME/.prime/agent/prompts"

if [ -d "$REPO_DIR/prime-agent/extensions/subagent" ]; then
  mkdir -p "$PA_EXT_DEST"
  cp -R "$REPO_DIR/prime-agent/extensions/subagent/." "$PA_EXT_DEST/"
  echo "  [ok] prime-agent/extensions/subagent -> $PA_EXT_DEST"
fi

if [ -d "$REPO_DIR/prime-agent/agents" ]; then
  mkdir -p "$PA_AGENTS_DEST"
  cp -R "$REPO_DIR/prime-agent/agents/." "$PA_AGENTS_DEST/"
  echo "  [ok] prime-agent/agents -> $PA_AGENTS_DEST"
fi

if [ -d "$REPO_DIR/prime-agent/prompts" ]; then
  mkdir -p "$PA_PROMPTS_DEST"
  cp -R "$REPO_DIR/prime-agent/prompts/." "$PA_PROMPTS_DEST/"
  echo "  [ok] prime-agent/prompts -> $PA_PROMPTS_DEST"
fi

echo "Done (v$VERSION). Restart omp / OpenCode / prime-agent (or /reload) to pick up changes."
