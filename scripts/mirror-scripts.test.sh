#!/usr/bin/env bash
# Prove the two invariants the review asked for: rsync failure is not
# reported as success, and drift output is not a plantable /tmp/name-$$ path.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYNC="$ROOT/scripts/mirror-sync.sh"
CHECK="$ROOT/scripts/mirror-check.sh"

bash -n "$SYNC"
bash -n "$CHECK"

# Source-level: the swallow that used to hide rsync failures, and the
# predictable temp path, must not come back.
if grep -nE '\|\|[[:space:]]*true' "$SYNC"; then
  echo "mirror-sync.sh still swallows errors with || true" >&2
  exit 1
fi
if grep -q '/tmp/mirror-check-\$\$' "$CHECK"; then
  echo "mirror-check.sh still writes /tmp/mirror-check-\$\$" >&2
  exit 1
fi
grep -q 'mktemp -d' "$CHECK"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/mirror-scripts-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/mirror/.git" "$WORK/bin"

cat > "$WORK/bin/rsync" << 'EOF'
#!/bin/sh
echo "fake rsync refusing to copy" >&2
exit 3
EOF
chmod 755 "$WORK/bin/rsync"

set +e
output="$(PATH="$WORK/bin:$PATH" "$SYNC" --mirror "$WORK/mirror" 2>&1)"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "mirror-sync.sh exited 0 even though rsync failed" >&2
  echo "$output" >&2
  exit 1
fi
case "$output" in
  *"Copied. The mirror repository was NOT committed"*)
    echo "mirror-sync.sh reported success after rsync failure" >&2
    echo "$output" >&2
    exit 1
    ;;
esac
case "$output" in
  *"Sync FAILED"*) ;;
  *)
    echo "mirror-sync.sh did not name the rsync failure" >&2
    echo "$output" >&2
    exit 1
    ;;
esac

echo "mirror script tests ok"
