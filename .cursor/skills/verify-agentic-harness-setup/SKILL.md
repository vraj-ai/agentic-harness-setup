---
name: verify-agentic-harness-setup
description: Prove agentic-harness-setup by syncing, capturing, and mirror-checking in a disposable home, plus a Pi install dry-run. Use before a PR, after edits to scripts, omp, opencode, prime-agent, or pi install, and whenever an agent must show the harness still deploys.
---

# Verify agentic-harness-setup

The operator-facing surfaces are shell scripts, not a server. Drive them with `verify.sh`. It uses a disposable `HOME`, a copy of the repo for capture, and a temporary pi mirror. It does not write the real home directory, and capture never runs against the checkout you have open.

## Launch

From the repo root, no install step is required beyond `bash`, `node`, `rsync`, and `diff` on `PATH`. Pi dry-run does not `npm install`.

```bash
.cursor/skills/verify-agentic-harness-setup/verify.sh all
```

Ready means the script prints `PASS all` and exits 0. There is no process to leave running. Each subcommand is its own run and removes its scratch directory on the way out.

## Doctor

```bash
.cursor/skills/verify-agentic-harness-setup/verify.sh doctor
```

Doctor is read-only. It checks `bash`, `node`, `rsync`, and `diff` are on `PATH`, `VERSION` is non-empty, the omp, OpenCode, Prime Agent, and Pi trees exist, and `bash -n` accepts `scripts/*.sh` plus this skill's `verify.sh`. A failing doctor means do not drive.

## Drive

Run one feature, or `all`:

```bash
.cursor/skills/verify-agentic-harness-setup/verify.sh sync
.cursor/skills/verify-agentic-harness-setup/verify.sh capture
.cursor/skills/verify-agentic-harness-setup/verify.sh mirror
.cursor/skills/verify-agentic-harness-setup/verify.sh pi-install
```

Recipes and the observable end states are in `features/`. Start from the index. Do not point `HOME` at the operator's real home. Do not pass the default mirror path (`~/Work/Projects/vraj-ai-pi`); the script always passes `--mirror` to a temp directory.

## Evidence

Proof is appended to `artifacts/verify-agentic-harness-setup/proof.txt`, with per-step `*.out` and `*.err` beside it. Override the directory with `VERIFY_PROOF_DIR` when a run must not share that folder.

The proof has to show the command, the exit code, and the resulting files:

- Sync: files under the disposable home match the repo, and `~/Work/skills` was not created.
- Capture: a seeded marker appears only in the repo copy; the open checkout has no marker.
- Mirror: an in-sync check exits 0, a drifted README exits 1, `--dry-run` leaves the drift, a real sync removes it and prints that it did not commit, and a missing `--mirror` path exits 2.
- Pi: `--dry-run` prints the link plan and does not create the agent directory.

`artifacts/` is gitignored. Paste `proof.txt` into the PR body. A dry-run that only prints a plan is not proof until the script also shows the agent directory is absent.

## Cleanup

The script traps `EXIT` and deletes the scratch directory it created with `mktemp`. It does not kill processes by name. It does not delete `artifacts/verify-agentic-harness-setup/` or `VERIFY_PROOF_DIR`.

## Helpers

`verify.sh` is the only helper. Invoke it as shown above. It must be executable.

After the surfaces change, run `/maintain-verification-skill` so this map stays honest. One PR per maintenance pass.
