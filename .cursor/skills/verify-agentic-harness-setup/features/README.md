# agentic-harness-setup verification map

This directory is the maintained source for verifying the operator-facing behavior of agentic-harness-setup. Read the index before driving, then use the matching feature file as the recipe.

## Baseline preconditions

- Start at the repo root, with `bash`, `node`, `rsync`, and `diff` on `PATH`.
- Run `.cursor/skills/verify-agentic-harness-setup/verify.sh doctor` and require `doctor ok`.
- The helper builds its own disposable `HOME`, repo copy, and mirror under `mktemp`. Never export the operator's real `HOME` into these runs.
- Do not drive `scripts/sync.sh` or `scripts/capture.sh` against the real home or the open checkout. The helper is the harness.

## Driving conventions

- Start every recipe from the baseline state unless its preconditions say otherwise.
- Treat every command as literal. Keep flags unchanged.
- Run actions through `.cursor/skills/verify-agentic-harness-setup/verify.sh <feature>`.
- Leave `artifacts/verify-agentic-harness-setup/` in place after the run.

## Proof and skip reporting

- Capture the command, stdout, stderr, exit code, and the file that changed.
- Record the feature id with the artifact.
- Report an unreachable path with the attempted command and the unmet precondition.
- Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the operator-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every operator entry point.
3. `Driving it with verify.sh` starts with `Preconditions:` and uses labeled bullets that pair each action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

## Features

- [Sync to live installs](./sync.md) copies omp, OpenCode, and Prime Agent into a disposable home.
- [Capture back into the repo](./capture.md) skips when nothing is seeded, and copies markers only into a repo copy.
- [Pi mirror drift](./mirror.md) reports drift, dry-runs without writing, syncs without committing, and rejects a missing path.
- [Pi install dry-run](./pi-install.md) prints the link plan and creates no agent directory.
