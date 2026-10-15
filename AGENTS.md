# AGENTS.md

Machine harness for this account. Skills live in [vraj-ai/skills](https://github.com/vraj-ai/skills). This repo versions omp Roles, OpenCode profiles, the Prime Agent `@`-mention harness, and the Pi tree. Why the stack is shaped this way: `CONTEXT/architecture.md`.

Self-merge is off (fleet ADR 0003). Open a PR. Do not merge it. Do not force-push `main`. No secrets.

## Verify, every time

Before a PR, run the verify skill and paste its proof into the PR body:

```bash
.cursor/skills/verify-agentic-harness-setup/verify.sh all
```

Proof is written to `artifacts/verify-agentic-harness-setup/`. That directory is gitignored. Cleanup deletes the disposable home and mirror, not the proof.

A change that skips this step is not done. `/maintain-verification-skill` keeps the feature map honest after the surfaces change.

## Which skill, when

pstack `poteto-mode` is the inner engineering loop. vraj-ai/skills owns the tracker and delivery. Use one path:

| Situation | What to run |
|---|---|
| One file, or the change is obvious | `ship` |
| Crosses modules, a design fork, or a bug whose cause is unknown | `ship`, and inside it poteto-mode: understand (`how` / `why`) → design (`architect`) → build → **verify** → `interrogate` → ship |
| More than one session, or a program of work | `grill` → `issues` → `ship` per issue. `snapshot` to hand off. `goals` only when the task is an autonomous plan (the omp `goals` Role). |

omp invocation Roles in `omp/agent/` autoload the skill of the same name: `grill`, `issues`, `ship`, `snapshot`, `goals`. Worker Roles (`researcher`, `builder`, `reviewer`, `adversary`, `small-task`) never spawn.

pstack does not file issues. `issues` does. When a `verify-*` feature exists, name it in the issue's Verification field.

Do not run two copies of the same pstack skill names. Cursor's pstack plugin and T3's t3-pstack both define `poteto-mode`. Pick the host you are in.

## Commands

```bash
./scripts/sync.sh          # repo -> live installs (uses $HOME)
./scripts/capture.sh       # skills or live installs -> this repo (writes the repo)
./scripts/mirror-check.sh  # pi/ vs a vraj-ai/pi clone; read-only
./scripts/mirror-sync.sh   # copy pi/ into that clone; never commits
```

Pi itself installs with `pi/install.sh` into `~/.pi/agent` (or `--agent-dir`). `sync.sh` does not install `pi/`.

Verification must use a disposable `HOME`. `capture.sh` writes into the tree that contains the script. The verify skill does both of those for you.
