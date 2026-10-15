# Architecture

Decisions for this harness. Status lives in git, PRs, and GitHub issues. There is no `progress.md`.

## What this repo is

It versions the machine overlay. Portable workflow skills stay in [vraj-ai/skills](https://github.com/vraj-ai/skills) (`harness/omp`, `harness/opencode`, and the `grill` / `issues` / `ship` / `snapshot` / `goals` skills). This repo deploys Role files, OpenCode agents, Prime Agent extensions, and the Pi tree.

| Tree | Live install | Deployed by |
|---|---|---|
| `omp/agent/` | `~/.omp/agent/agents` (`$OMP_AGENTS_DIR`) | `scripts/sync.sh` |
| `opencode/` | `~/.config/opencode` (`$OPENCODE_CONFIG_DIR`) | `scripts/sync.sh` |
| `prime-agent/` | `~/.prime/agent` | `scripts/sync.sh` |
| `pi/` | `~/.pi/agent` | `pi/install.sh`, not `sync.sh` |

When `~/Work/skills/harness` exists, `sync.sh` also copies omp and OpenCode templates there, and `capture.sh` prefers that tree over the live config dirs. `scripts/mirror-check.sh` and `scripts/mirror-sync.sh` compare or copy `pi/` against a local clone of `github.com/vraj-ai/pi`. The mirror scripts never commit or push.

`pi/` is the Pi agent configuration formerly published as `vraj-ai/Pi-Setup`. `prime-agent/` is the older `@`-mention harness. They install to different directories.

## Current stack

Recorded from the captain's operating setup. This repo does not install Herdr, Devin, Cursor, or T3. It only has to stay readable by all of them.

1. **Herdr fan-out.** Herdr fans work out to two coding arms: Claude Code, and pi. Both arms run on OpenCode Go.
2. **Devin CLI.** Whole tickets go to the Devin CLI with this repo's `AGENTS.md` and `.cursor/skills/verify-agentic-harness-setup/` in the brief. No Devin pstack plugin is recorded here.
3. **Cursor cloud agents.** pstack's home runtime. They read `AGENTS.md`, run the verify skill, and open a PR. They do not merge.
4. **T3 Code with t3-pstack.** T3 is the daily-driver host. t3-pstack installs into the Claude Code and Codex homes T3 uses. Inside T3 the commands are `/t3-pstack:<name>` (Claude Code) and `$t3-pstack:<name>` (Codex). Setup writes `~/.config/t3-pstack/models.md`. Install, from the t3-pstack README as recorded in the pstack migration notes: `npx -y github:chhoumann/t3-pstack install`, then `doctor`, then `/t3-pstack:setup-pstack` in a T3 thread.
5. **pstack plugin.** Installed in Cursor. Run `/setup-pstack` once per machine. It writes `~/.cursor/rules/pstack-models.mdc` and applies on the next chat. `/poteto-mode` is the inner loop: understand → design → build → verify → interrogate → ship. `/create-verification-skill` is how this repo got `.cursor/skills/verify-agentic-harness-setup/`.

Checked-in profiles that already name OpenCode Go (`opencode/` and the matching `prime-agent/agents/` copies):

| Profile | Model |
|---|---|
| `contributor`, `council-glm` | `opencode-go/glm-5.2` |
| `council-grok`, `council-adversary` | `opencode-go/grok-4.5` |

Other checked-in council profiles use OpenRouter or `openai/gpt-5.6-sol`. `pi/settings.example.json` still defaults to provider `openai-codex`, model `gpt-5.6-sol`. That file was not rewritten to claim an OpenCode Go default, because no model slug for that default was specified.

Inside Pi, the extension at `pi/extensions/subagents` is also named Herdr. It is a different surface: a read-only subagent fleet (`pi`, `claude`, `codex`, `agy`, `omp`, `grok`), max 4 concurrent, no human takeover. `claude` is Claude Code via the Claude Agent SDK. The outer Herdr fan-out above is the session host; this extension is the fleet inside a Pi session.

## Authority

Fleet ADR 0003 stays off. Agents open one PR and stop. Evidence for a change is the verify-skill log at the PR's head, plus an `interrogate` verdict when poteto-mode ran.

## Inner loop and outer skills

pstack never touches the tracker. `grill`, `issues`, `ship`, and `snapshot` stay the outer skills (see `AGENTS.md` for which one to pick). `ship` remains the delivery wrapper. For multi-module work, a design fork, or an unknown cause, poteto-mode's Feature or Bug-fix playbook runs inside `ship`, and `interrogate` is the independent review when no PR bot is configured.

## Removed

`claude-code/agents/debugger-pi-agent.md` targeted a Pi workflow rail (`/planner` → `/coder` → `/debugger` → `/reviewer`), test paths under `extensions/workflow/`, and a GitHub Project item. `pi/README.md` states that rail is gone: no `/flow`, no `/mode`, no `workflow` tool. `sync.sh` never installed `claude-code/`. The file was removed so an agent would not follow those paths.
