# Pi mirror drift

Mirror check compares `pi/` with a local clone of `github.com/vraj-ai/pi` and prints drift. Mirror sync copies `pi/` into that clone and stops. It does not commit or push. A missing `--mirror` path is an error, not a sync to the default directory.

## Sub-features

- `mirror-in-sync` exits 0 when the clone matches `pi/`.
- `mirror-drift` exits 1 and names `README.md` after a one-line edit.
- `mirror-dry-run` prints the copy plan and leaves the drifted line in place.
- `mirror-sync-nocommit` replaces the drifted file, prints that it did not commit, and a following check exits 0.
- `mirror-missing-path` exits 2 and prints `--mirror needs a path`.
- `mirror-rsync-failure` is the repo test `scripts/mirror-scripts.test.sh`: a failing rsync is not reported as a successful copy.

## How to get to it (user POV)

- Run `./scripts/mirror-check.sh --mirror <clone>` before publishing the pi mirror.
- Run `./scripts/mirror-sync.sh --mirror <clone>` to copy, then review and commit in the mirror clone yourself.
- Run `./scripts/mirror-sync.sh --dry-run --mirror <clone>` to see the plan.

## Driving it with verify.sh

Preconditions:

- `verify.sh doctor` prints `doctor ok`, including `rsync` on `PATH`.
- The helper builds a temp mirror from `pi/` and passes `--mirror` to it. There is no step that talks to GitHub.

- **In sync.** Exit 0 for the first check. `mirror-check-sync.out` contains `In sync.`
- **Drift.** Append a line to the temp mirror's `README.md`. The check exits 1. `mirror-check-drift.out` contains `[DIFF] README.md` and a line that is exactly `Drift found.` A content diff does not claim paths are missing.
- **Dry run.** `mirror-sync --dry-run` exits 0 and the drifted line is still in the temp `README.md`.
- **Sync.** `mirror-sync` exits 0, stdout contains `NOT committed or pushed`, the drifted line is gone, and a following check exits 0.
- **Missing path.** `mirror-sync.sh --mirror` with no path exits 2. `mirror-sync-no-path.err` contains `--mirror needs a path`.
- **Rsync failure.** `scripts/mirror-scripts.test.sh` exits 0 and prints `mirror script tests ok`.
- **Proof.** Those logs sit in `artifacts/verify-agentic-harness-setup/`. `proof.txt` contains `mirror ok`.

## Gotchas

- The default mirror path is `~/Work/Projects/vraj-ai-pi` or `$PI_MIRROR_DIR`. Omitting `--mirror` on a machine that has that clone writes the operator's clone. This recipe always passes a temp path.
- `--dry-run` is not proof that the copy is clean. The drifted line must still be present after the dry run, and absent only after the real sync.
- `mirror-sync.sh` never commits. A clean check only proves the worktree matches `pi/`.
- `package-lock.json` is gitignored and may be absent. Both scripts skip paths missing from `pi/`. Do not treat a `[skip]` for an absent path as drift.
