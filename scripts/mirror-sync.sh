#!/usr/bin/env bash
# agentic-harness-setup - mirror-sync.sh
#
# Copy the canonical package (pi/ in this repo) into a local clone of the
# published mirror (github.com/vraj-ai/pi).
#
# It writes files into the mirror clone and stops there. It does not commit,
# does not push, and does not touch the mirror's git history - publishing is a
# deliberate act, and this script exists to make the diff reviewable, not to
# make it disappear.
#
#   scripts/mirror-sync.sh [--mirror <path>] [--dry-run] [--delete]
#
#   --dry-run  show what would be written, change nothing
#   --delete   also remove mirror files the canonical package no longer has
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CANONICAL="$REPO_DIR/pi"
MIRROR="${PI_MIRROR_DIR:-$HOME/Work/Projects/vraj-ai-pi}"
DRY_RUN=0
DELETE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --mirror) MIRROR="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --delete) DELETE=1; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -d "$CANONICAL" ] || { echo "No canonical package at $CANONICAL" >&2; exit 2; }
if [ ! -d "$MIRROR" ]; then
  echo "No mirror clone at $MIRROR" >&2
  echo "Clone it first:  git clone https://github.com/vraj-ai/pi.git $MIRROR" >&2
  exit 2
fi
if [ "$(cd "$MIRROR" && pwd)" = "$REPO_DIR" ] || [ "$(cd "$MIRROR" && pwd)" = "$CANONICAL" ]; then
  echo "Refusing to sync a repository onto itself." >&2
  exit 2
fi

# Keep in sync with mirror-check.sh.
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

RSYNC_EXCLUDES=(
  --exclude '.git/'
  --exclude 'node_modules/'
  --exclude '.DS_Store'
  --exclude '*.sqlite'
  --exclude '*.sqlite-wal'
  --exclude '*.sqlite-shm'
  --exclude '.vraj/'
)

VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"
echo "agentic-harness-setup v$VERSION - pi/ -> $MIRROR"
[ "$DRY_RUN" = "1" ] && echo "(dry run: nothing will be written)"
echo

flags=(-a --itemize-changes)
[ "$DRY_RUN" = "1" ] && flags+=(--dry-run)
[ "$DELETE" = "1" ] && flags+=(--delete)

if ! command -v rsync > /dev/null 2>&1; then
  echo "rsync is required but not installed." >&2
  exit 2
fi

# A partial copy that reports success is worse than a loud failure: the mirror
# would look synced while missing files. `pipefail` plus an explicit status
# check means any rsync error aborts and is named.
set -o pipefail
failed=()

for path in "${PATHS[@]}"; do
  src="$CANONICAL/$path"
  if [ ! -e "$src" ]; then
    if [ "$DELETE" = "1" ] && [ -e "$MIRROR/$path" ]; then
      echo "  [delete] $path (not in canonical)"
      [ "$DRY_RUN" = "1" ] || rm -rf "$MIRROR/$path"
    else
      echo "  [skip] $path (not in canonical)"
    fi
    continue
  fi
  if [ -d "$src" ]; then
    mkdir -p "$MIRROR/$path"
    rsync "${flags[@]}" "${RSYNC_EXCLUDES[@]}" "$src/" "$MIRROR/$path/" \
      | sed 's/^/  /'
  else
    rsync "${flags[@]}" "${RSYNC_EXCLUDES[@]}" "$src" "$MIRROR/$path" \
      | sed 's/^/  /'
  fi
  status=$?
  if [ "$status" -ne 0 ]; then
    echo "  [FAIL] $path (rsync exit $status)" >&2
    failed+=("$path")
  fi
done

if [ "${#failed[@]}" -ne 0 ]; then
  echo >&2
  echo "Sync FAILED for: ${failed[*]}" >&2
  echo "The mirror is now partially written. Fix the cause and re-run before publishing." >&2
  exit 1
fi

echo
if [ "$DRY_RUN" = "1" ]; then
  echo "Dry run complete. Re-run without --dry-run to write."
  exit 0
fi

echo "Copied. The mirror repository was NOT committed or pushed."
if [ -d "$MIRROR/.git" ]; then
  echo
  echo "Review and publish yourself:"
  echo "  git -C $MIRROR status"
  echo "  git -C $MIRROR diff"
  echo "  git -C $MIRROR add -A && git -C $MIRROR commit -m 'sync from agentic-harness-setup v$VERSION'"
  echo "  git -C $MIRROR push"
fi
