#!/usr/bin/env bash
# Prove agentic-harness-setup the way an operator runs it.
# Disposable HOME, a copied repo for capture, and a temporary pi mirror.
# Writes proof under artifacts/ and deletes only the scratch tree.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
PROOF="${VERIFY_PROOF_DIR:-$ROOT/artifacts/verify-agentic-harness-setup}"
MARKER="zz-verify-marker.md"
WORK=""

usage() {
  echo "Usage: verify.sh {doctor|sync|capture|mirror|pi-install|all}" >&2
  exit 2
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing command: $1" >&2
    exit 1
  }
}

log() {
  printf '%s\n' "$*" | tee -a "$PROOF/proof.txt"
}

# Runs a command, tees its output into the proof directory, and stores the
# exit code in RECORDED_STATUS. Always returns 0 so an expected failure
# (mirror drift, missing --mirror) does not trip `set -e`. `set -e` is
# global in bash, so the previous option set is restored before return.
run_logged() {
  local name="$1"
  shift
  local flags="$-"
  log ""
  log "\$ $*"
  set +e
  "$@" >"$PROOF/${name}.out" 2>"$PROOF/${name}.err"
  RECORDED_STATUS=$?
  cat "$PROOF/${name}.out" "$PROOF/${name}.err" | tee -a "$PROOF/proof.txt"
  log "exit $RECORDED_STATUS"
  case "$flags" in
    *e*) set -e ;;
  esac
  return 0
}

doctor() {
  need bash
  need node
  need rsync
  need diff
  local version
  version="$(tr -d '[:space:]' <"$ROOT/VERSION")"
  [ -n "$version" ]
  [ -d "$ROOT/omp/agent" ]
  [ -d "$ROOT/opencode/agent" ]
  [ -d "$ROOT/opencode/command" ]
  [ -d "$ROOT/prime-agent/extensions/subagent" ]
  [ -d "$ROOT/prime-agent/agents" ]
  [ -d "$ROOT/prime-agent/prompts" ]
  [ -d "$ROOT/pi" ]
  bash -n "$ROOT/scripts/sync.sh"
  bash -n "$ROOT/scripts/capture.sh"
  bash -n "$ROOT/scripts/mirror-check.sh"
  bash -n "$ROOT/scripts/mirror-sync.sh"
  bash -n "$ROOT/scripts/mirror-scripts.test.sh"
  bash -n "${BASH_SOURCE[0]}"
  log "doctor ok (VERSION $version)"
}

copy_repo() {
  local dest="$1"
  mkdir -p "$dest"
  tar -C "$ROOT" \
    --exclude .git \
    --exclude artifacts \
    --exclude node_modules \
    -cf - . | tar -C "$dest" -xf -
}

assert_same() {
  local src="$1" dst="$2"
  [ -f "$dst" ] || {
    echo "missing $dst" >&2
    return 1
  }
  cmp -s "$src" "$dst" || {
    echo "differs: $dst" >&2
    return 1
  }
}

drive_sync() {
  local home="$WORK/sync-home"
  mkdir -p "$home"
  local version
  version="$(tr -d '[:space:]' <"$ROOT/VERSION")"
  run_logged sync env HOME="$home" "$ROOT/scripts/sync.sh"
  [ "$RECORDED_STATUS" -eq 0 ]
  assert_same "$ROOT/opencode/agent/goals.md" "$home/.config/opencode/agent/goals.md"
  assert_same "$ROOT/opencode/command/goal.md" "$home/.config/opencode/command/goal.md"
  assert_same "$ROOT/omp/agent/grill.md" "$home/.omp/agent/agents/grill.md"
  assert_same "$ROOT/omp/agent/ship.md" "$home/.omp/agent/agents/ship.md"
  assert_same "$ROOT/prime-agent/extensions/subagent/index.ts" \
    "$home/.prime/agent/extensions/subagent/index.ts"
  assert_same "$ROOT/prime-agent/agents/contributor.md" \
    "$home/.prime/agent/agents/contributor.md"
  assert_same "$ROOT/prime-agent/prompts/implement.md" \
    "$home/.prime/agent/prompts/implement.md"
  grep -q "agentic-harness-setup v$version" "$PROOF/sync.out"
  [ ! -e "$home/Work/skills" ]
  log "sync ok -> $home"
}

drive_capture() {
  local empty_home="$WORK/capture-empty-home"
  local empty_repo="$WORK/capture-empty-repo"
  local seeded_home="$WORK/capture-seed-home"
  local seeded_repo="$WORK/capture-seed-repo"
  mkdir -p "$empty_home"
  copy_repo "$empty_repo"
  local before
  before="$(cksum "$empty_repo/opencode/agent/goals.md")"
  run_logged capture-empty env HOME="$empty_home" "$empty_repo/scripts/capture.sh"
  [ "$RECORDED_STATUS" -eq 0 ]
  [ "$(cksum "$empty_repo/opencode/agent/goals.md")" = "$before" ]
  grep -q "no OpenCode templates found" "$PROOF/capture-empty.out"
  grep -q "no omp Role templates found" "$PROOF/capture-empty.out"

  mkdir -p \
    "$seeded_home/Work/skills/harness/opencode/agent" \
    "$seeded_home/Work/skills/harness/omp/agent" \
    "$seeded_home/.prime/agent/agents" \
    "$seeded_home/.prime/agent/extensions/subagent" \
    "$seeded_home/.prime/agent/prompts"
  printf 'verify-marker\n' >"$seeded_home/Work/skills/harness/opencode/agent/$MARKER"
  printf 'verify-marker\n' >"$seeded_home/Work/skills/harness/omp/agent/$MARKER"
  printf 'verify-marker\n' >"$seeded_home/.prime/agent/agents/$MARKER"
  printf 'verify-marker\n' >"$seeded_home/.prime/agent/extensions/subagent/$MARKER"
  printf 'verify-marker\n' >"$seeded_home/.prime/agent/prompts/$MARKER"
  copy_repo "$seeded_repo"
  run_logged capture-seed env HOME="$seeded_home" "$seeded_repo/scripts/capture.sh"
  [ "$RECORDED_STATUS" -eq 0 ]
  cmp -s "$seeded_home/Work/skills/harness/opencode/agent/$MARKER" \
    "$seeded_repo/opencode/agent/$MARKER"
  cmp -s "$seeded_home/Work/skills/harness/omp/agent/$MARKER" \
    "$seeded_repo/omp/agent/$MARKER"
  cmp -s "$seeded_home/.prime/agent/agents/$MARKER" \
    "$seeded_repo/prime-agent/agents/$MARKER"
  cmp -s "$seeded_home/.prime/agent/prompts/$MARKER" \
    "$seeded_repo/prime-agent/prompts/$MARKER"
  [ -f "$seeded_repo/opencode/agent/goals.md" ]
  [ ! -e "$ROOT/opencode/agent/$MARKER" ]
  [ ! -e "$ROOT/omp/agent/$MARKER" ]
  [ ! -e "$ROOT/prime-agent/agents/$MARKER" ]
  log "capture ok (empty skip + seeded copy; real repo untouched)"
}

drive_mirror() {
  local mirror="$WORK/pi-mirror"
  mkdir -p "$mirror/.git"
  local path
  local paths=(
    extensions skills themes scripts docs assets
    AGENTS.md SYSTEM.md PROVENANCE.md README.md SETUP.md
    keybindings.json package.json package-lock.json
    settings.example.json tsconfig.json install.sh install.ps1
  )
  for path in "${paths[@]}"; do
    [ -e "$ROOT/pi/$path" ] || continue
    mkdir -p "$(dirname "$mirror/$path")"
    cp -a "$ROOT/pi/$path" "$mirror/$path"
  done
  run_logged mirror-check-sync "$ROOT/scripts/mirror-check.sh" --mirror "$mirror"
  [ "$RECORDED_STATUS" -eq 0 ]
  printf '\nverify drift\n' >>"$mirror/README.md"
  run_logged mirror-check-drift "$ROOT/scripts/mirror-check.sh" --mirror "$mirror"
  [ "$RECORDED_STATUS" -eq 1 ]
  grep -q "\[DIFF\] README.md" "$PROOF/mirror-check-drift.out"
  grep -qx "Drift found." "$PROOF/mirror-check-drift.out"
  run_logged mirror-sync-dry "$ROOT/scripts/mirror-sync.sh" --mirror "$mirror" --dry-run
  [ "$RECORDED_STATUS" -eq 0 ]
  grep -q "verify drift" "$mirror/README.md"
  run_logged mirror-sync "$ROOT/scripts/mirror-sync.sh" --mirror "$mirror"
  [ "$RECORDED_STATUS" -eq 0 ]
  grep -q "NOT committed or pushed" "$PROOF/mirror-sync.out"
  if grep -q "verify drift" "$mirror/README.md"; then
    echo "mirror-sync left the drifted line in place" >&2
    return 1
  fi
  run_logged mirror-check-after "$ROOT/scripts/mirror-check.sh" --mirror "$mirror"
  [ "$RECORDED_STATUS" -eq 0 ]
  run_logged mirror-scripts "$ROOT/scripts/mirror-scripts.test.sh"
  [ "$RECORDED_STATUS" -eq 0 ]
  run_logged mirror-sync-no-path "$ROOT/scripts/mirror-sync.sh" --mirror
  [ "$RECORDED_STATUS" -eq 2 ]
  grep -q -- "--mirror needs a path" "$PROOF/mirror-sync-no-path.err"
  log "mirror ok"
}

drive_pi_install() {
  local agent="$WORK/pi-agent"
  run_logged pi-dry-run \
    env HOME="$WORK/pi-home" \
    node "$ROOT/pi/scripts/install.mjs" --dry-run --agent-dir "$agent"
  [ "$RECORDED_STATUS" -eq 0 ]
  [ ! -e "$agent" ]
  grep -q "Dry run:" "$PROOF/pi-dry-run.out"
  grep -q "Would link" "$PROOF/pi-dry-run.out"
  if [ -d "$ROOT/pi/node_modules" ]; then
    log "pi node_modules already present; dry-run does not repeat the install line"
  else
    grep -q "Would install repository dependencies." "$PROOF/pi-dry-run.out"
  fi
  log "pi dry-run ok (no agent dir created)"
}

finish() {
  local status=$?
  if [ -n "$WORK" ] && [ -d "$WORK" ]; then
    rm -rf "$WORK"
  fi
  if [ "$status" -ne 0 ]; then
    log "FAILED status $status"
  fi
  exit "$status"
}

main() {
  local cmd="${1:-}"
  [ -n "$cmd" ] || usage
  case "$cmd" in
    doctor | sync | capture | mirror | pi-install | all) ;;
    *) usage ;;
  esac
  mkdir -p "$PROOF"
  : >"$PROOF/proof.txt"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/verify-agentic-harness.XXXXXX")"
  trap finish EXIT INT TERM
  log "verify-agentic-harness-setup"
  log "repo $ROOT"
  log "proof $PROOF"
  doctor
  case "$cmd" in
    doctor) ;;
    sync) drive_sync ;;
    capture) drive_capture ;;
    mirror) drive_mirror ;;
    pi-install) drive_pi_install ;;
    all)
      drive_sync
      drive_capture
      drive_mirror
      drive_pi_install
      ;;
  esac
  log ""
  log "PASS $cmd"
}

main "$@"
