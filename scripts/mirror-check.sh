#!/usr/bin/env bash
# agentic-harness-setup - mirror-check.sh
#
# Report drift between the canonical package (pi/ in this repo) and the
# published mirror (github.com/vraj-ai/pi).
#
# Read-only in both directions: it never writes to the mirror clone and never
# writes to this repo. Use mirror-sync.sh to actually push a copy.
#
#   scripts/mirror-check.sh [--mirror <path>]
#
# Exit codes:
#   0  in sync
#   1  drift found (paths printed)
#   2  could not run the comparison
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$REPO_DIR/pi"
MIRROR="${PI_MIRROR_DIR:-$HOME/Work/Projects/vraj-ai-pi}"

while [ $# -gt 0 ]; do
  case "$1" in
    --mirror) MIRROR="${2:-}"; shift 2 || { echo "--mirror needs a path" >&2; exit 2; } ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$CANONICAL" ]; then
  echo "No canonical package at $CANONICAL" >&2
  exit 2
fi
if [ ! -d "$MIRROR" ]; then
  echo "No mirror clone at $MIRROR" >&2
  echo "Clone it first:  git clone https://github.com/vraj-ai/pi.git $MIRROR" >&2
  echo "Or point somewhere else with --mirror / PI_MIRROR_DIR." >&2
  exit 2
fi

# Everything the mirror is meant to carry. Anything not listed here is
# deliberately local (node_modules, the sqlite index, scratch files).
# Keep in sync with mirror-sync.sh.
PATHS=(
  extensions
  skills
  themes
  scripts
  docs
  assets
  AGENTS.md
  SYSTEM.md
  PROVENANCE.md
  README.md
  SETUP.md
  keybindings.json
  package.json
  package-lock.json
  settings.example.json
  tsconfig.json
  install.sh
  install.ps1
)

EXCLUDES=(
  --exclude .git
  --exclude node_modules
  --exclude .DS_Store
  --exclude '*.sqlite'
  --exclude '*.sqlite-wal'
  --exclude '*.sqlite-shm'
  --exclude .vraj
)

# Drift output goes through a private temp directory rather than a predictable
# /tmp/<name>-$$ path, which is symlink-plantable on a shared machine.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/mirror-check.XXXXXX")" || {
  echo "Could not create a temporary directory" >&2
  exit 2
}
chmod 700 "$WORK"
trap 'rm -rf "$WORK"' EXIT INT TERM

drift=0
missing=0

echo "canonical: $CANONICAL"
echo "mirror:    $MIRROR"
echo

for path in "${PATHS[@]}"; do
  src="$CANONICAL/$path"
  dst="$MIRROR/$path"

  if [ ! -e "$src" ]; then
    echo "  [skip] $path (not in canonical)"
    continue
  fi
  if [ ! -e "$dst" ]; then
    echo "  [MISSING IN MIRROR] $path"
    missing=$((missing + 1))
    drift=1
    continue
  fi

  if diff -rq "${EXCLUDES[@]}" "$src" "$dst" > "$WORK/diff.txt" 2>&1; then
    echo "  [ok]   $path"
  else
    echo "  [DIFF] $path"
    sed 's/^/         /' "$WORK/diff.txt"
    drift=1
  fi
done

echo
if [ -d "$MIRROR/.git" ]; then
  echo "mirror HEAD: $(git -C "$MIRROR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  dirty="$(git -C "$MIRROR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  [ "$dirty" != "0" ] && echo "mirror has $dirty uncommitted change(s)"
fi

if [ "$drift" -eq 0 ]; then
  echo "In sync."
else
  echo "Drift found${missing:+ ($missing path(s) missing in the mirror)}."
  echo "Run scripts/mirror-sync.sh to copy the canonical package over."
fi
exit "$drift"
