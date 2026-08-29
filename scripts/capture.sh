#!/usr/bin/env bash
# agentic-harness-setup — capture.sh (live installs / skills -> repo)
#
# Prefer ~/Work/skills/harness when present (vskills is the template source).
# Fall back to live ~/.config/opencode and ~/.omp/agent/agents.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$REPO_DIR/VERSION")"

echo "agentic-harness-setup v$VERSION — capturing into repo"

SKILLS_OC="$HOME/Work/skills/harness/opencode"
OPENCODE_LIVE="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
if [ -d "$SKILLS_OC/agent" ]; then
  OPENCODE_SRC="$SKILLS_OC"
elif [ -d "$OPENCODE_LIVE/agent" ]; then
  OPENCODE_SRC="$OPENCODE_LIVE"
else
  OPENCODE_SRC=""
fi

if [ -n "$OPENCODE_SRC" ]; then
  mkdir -p "$REPO_DIR/opencode/agent" "$REPO_DIR/opencode/command"
  cp -R "$OPENCODE_SRC/agent/." "$REPO_DIR/opencode/agent/"
  [ -d "$OPENCODE_SRC/command" ] && cp -R "$OPENCODE_SRC/command/." "$REPO_DIR/opencode/command/"
  echo "  [ok] $OPENCODE_SRC -> opencode/"
else
  echo "  [skip] no OpenCode templates found"
fi

SKILLS_OMP="$HOME/Work/skills/harness/omp/agent"
OMP_LIVE="${OMP_AGENTS_DIR:-$HOME/.omp/agent/agents}"
if [ -d "$SKILLS_OMP" ]; then
  OMP_SRC="$SKILLS_OMP"
elif [ -d "$OMP_LIVE" ]; then
  OMP_SRC="$OMP_LIVE"
else
  OMP_SRC=""
fi

if [ -n "$OMP_SRC" ]; then
  mkdir -p "$REPO_DIR/omp/agent"
  cp -R "$OMP_SRC/." "$REPO_DIR/omp/agent/"
  echo "  [ok] $OMP_SRC -> omp/agent/"
else
  echo "  [skip] no omp Role templates found"
fi

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
  cp -R "$REPO_DIR/prime-agent/agents/." "$REPO_DIR/prime-agent/agents/" 2>/dev/null || true
  cp -R "$PA_AGENTS_SRC/." "$REPO_DIR/prime-agent/agents/"
  echo "  [ok] $PA_AGENTS_SRC -> prime-agent/agents/"
fi

if [ -d "$PA_PROMPTS_SRC" ]; then
  mkdir -p "$REPO_DIR/prime-agent/prompts"
  cp -R "$PA_PROMPTS_SRC/." "$REPO_DIR/prime-agent/prompts/"
  echo "  [ok] $PA_PROMPTS_SRC -> prime-agent/prompts/"
fi

echo "Captured. Review the diff and bump VERSION if you commit."
