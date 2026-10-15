# Pi install dry-run

The Pi installer links `pi/` into an agent directory. Dry-run prints that plan and does not create the directory, the backup, or `settings.json`.

## Sub-features

- `pi-dry-run-plan` prints `Dry run:` and a `Would link` line for each resource.
- `pi-dry-run-deps` prints `Would install repository dependencies.` when `pi/node_modules` is absent.
- `pi-dry-run-no-write` leaves the requested `--agent-dir` nonexistent.

## How to get to it (user POV)

- Run `pi/install.sh` to install into `~/.pi/agent`.
- Run `node pi/scripts/install.mjs --dry-run --agent-dir <path>` to see the plan for a specific directory.
- Roll back a real install with `node pi/scripts/install.mjs --rollback` only after a real install. This feature does not roll back, because dry-run creates nothing to roll back.

## Driving it with verify.sh

Preconditions:

- `verify.sh doctor` prints `doctor ok`, including `node` on `PATH`.
- `pi/node_modules` may be absent. The dry-run must not create it.

- **Dry run.** Run `.cursor/skills/verify-agentic-harness-setup/verify.sh pi-install`. Exit code `0`.
- **Plan.** `pi-dry-run.out` contains `Dry run:` and `Would link`. If `pi/node_modules` does not exist, it also contains `Would install repository dependencies.`
- **No directory.** The agent path the helper chose does not exist after the command.
- **Proof.** `proof.txt` contains `pi dry-run ok`.

## Gotchas

- `pi/install.sh` without `--dry-run` writes `~/.pi/agent` and may `npm install` inside `pi/`. Verification stops at dry-run.
- Dry-run refuses a target inside the checkout. The helper uses a temp directory.
- When `pi/node_modules` already exists, the installer skips the dependency line. Do not fail that case for a missing "Would install" sentence; do fail it if an agent directory appears.
- A printed plan is not proof by itself. The absent agent directory is the side effect that matters.
