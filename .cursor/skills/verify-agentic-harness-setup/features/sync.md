# Sync to live installs

Sync copies the repo's omp Roles, OpenCode profiles, and Prime Agent harness into the home directory an operator would reload. It does not install Pi, and it does not create a skills clone that was not already there.

## Sub-features

- `sync-opencode` installs `opencode/agent` and `opencode/command`.
- `sync-omp` installs `omp/agent` into `~/.omp/agent/agents`.
- `sync-prime` installs the subagent extension, agents, and prompts under `~/.prime/agent`.
- `sync-no-skills-clone` leaves `~/Work/skills` absent when the operator has no skills checkout.

## How to get to it (user POV)

- Run `./scripts/sync.sh` from a checkout after a clone or a version bump.
- Reload omp, OpenCode, or Prime Agent.

## Driving it with verify.sh

Preconditions:

- `verify.sh doctor` prints `doctor ok`.
- The helper's disposable home starts empty.

- **Sync.** Run `.cursor/skills/verify-agentic-harness-setup/verify.sh sync`. Exit code `0`. `proof.txt` contains `agentic-harness-setup v` plus the `VERSION` file contents, then `sync ok`.
- **OpenCode landed.** The disposable home's `.config/opencode/agent/goals.md` and `.config/opencode/command/goal.md` match the repo byte for byte.
- **omp landed.** `.omp/agent/agents/grill.md` and `.omp/agent/agents/ship.md` match the repo.
- **Prime Agent landed.** `.prime/agent/extensions/subagent/index.ts`, `.prime/agent/agents/contributor.md`, and `.prime/agent/prompts/implement.md` match the repo.
- **No skills clone invented.** The disposable home has no `Work/skills` directory.
- **Proof.** `artifacts/verify-agentic-harness-setup/sync.out` keeps the script's own `[ok]` lines.

## Gotchas

- `sync.sh` follows the real `$HOME` unless the helper replaces it. Running it by hand writes the operator's live config.
- Prime Agent paths have no override other than `HOME`. OpenCode honors `$OPENCODE_CONFIG_DIR` and omp honors `$OMP_AGENTS_DIR`; a partial override still writes Prime Agent into `$HOME`.
- If `~/Work/skills/harness` already exists, sync also copies templates there. The disposable home must not contain that directory, or this recipe is no longer the empty-clone case.
- Pi is not part of this command. A home with no `~/.pi/agent` is the expected result.
