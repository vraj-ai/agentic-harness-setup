# Capture back into the repo

Capture copies omp, OpenCode, and Prime Agent templates into the repo that contains `scripts/capture.sh`. With nothing seeded it skips and leaves files alone. With a skills checkout seeded, those files win over the live config dirs.

## Sub-features

- `capture-skip` reports that no OpenCode or omp templates exist and does not change `goals.md`.
- `capture-skills` copies a marker from `~/Work/skills/harness` into the repo copy.
- `capture-prime` copies markers from `~/.prime/agent` into the repo copy.
- `capture-isolated` does not write the marker into the open checkout.

## How to get to it (user POV)

- Run `./scripts/capture.sh` before committing a snapshot taken from the skills repo or from live installs.
- Review the diff and bump `VERSION` if agents, Roles, or scripts changed.

## Driving it with verify.sh

Preconditions:

- `verify.sh doctor` prints `doctor ok`.
- The open checkout does not already contain `zz-verify-marker.md`.

- **Skip.** The helper runs capture in an empty home against a copy of the repo. Exit code `0`. Stdout contains `no OpenCode templates found` and `no omp Role templates found`. The copy's `opencode/agent/goals.md` checksum is unchanged.
- **Seed and capture.** The helper writes `zz-verify-marker.md` under the disposable skills harness and `~/.prime/agent`, then runs capture against a second repo copy. Exit code `0`.
- **Markers landed in the copy.** `opencode/agent/zz-verify-marker.md`, `omp/agent/zz-verify-marker.md`, `prime-agent/agents/zz-verify-marker.md`, and `prime-agent/prompts/zz-verify-marker.md` in the copy match the seeded files. `opencode/agent/goals.md` is still present.
- **Open checkout untouched.** The real repo has no `zz-verify-marker.md` under `opencode/agent`, `omp/agent`, or `prime-agent/agents`.
- **Proof.** `capture-empty.out` and `capture-seed.out` are in the proof directory. `proof.txt` contains `capture ok`.

## Gotchas

- `capture.sh` computes the repo from its own path. Running the checkout's script writes this checkout. The helper runs a copy of the script.
- A skills tree at `~/Work/skills/harness` is preferred over `~/.config/opencode` and `~/.omp`. Seeding only the live config dirs does not test the skills path.
- `cp -R` merges. Capture will not delete a Role that the source no longer has. Absence of a file is not proof that capture removed it.
- Prime Agent is captured only from `~/.prime/agent`, never from the skills repo.
