# agentic-harness-setup

Versioned machine harness for the coding agents on this account. It snapshots
the **omp Roles**, **OpenCode** profiles, and the **Prime Agent** `@`-mention
harness, plus the **Pi** tree (`pi/`, formerly `vraj-ai/Pi-Setup`). Sync scripts
keep live installs aligned with [vraj-ai/skills](https://github.com/vraj-ai/skills).

Current version: **0.4.1** (see [`VERSION`](VERSION)).

Skills stay portable. This repo is the machine overlay. Workflow skills live in
`vraj-ai/skills`. Agents start at [`AGENTS.md`](AGENTS.md). The operating stack
and the decisions behind it are in [`CONTEXT/architecture.md`](CONTEXT/architecture.md).

Self-merge is off (fleet ADR 0003).

## Layout

```
agentic-harness-setup/
├── VERSION
├── AGENTS.md
├── CONTEXT/                 # why: architecture and glossary. No progress file.
├── README.md
├── omp/agent/               # Invocation + Worker Role templates
├── opencode/                # OpenCode agents + slash commands
│   ├── agent/
│   └── command/
├── prime-agent/             # Prime Agent @-mention harness -> ~/.prime/agent
│   ├── extensions/subagent/
│   ├── agents/
│   └── prompts/
├── pi/                      # Pi config -> ~/.pi/agent via pi/install.sh
└── scripts/
    ├── sync.sh              # repo -> live installs
    ├── capture.sh           # skills/live -> repo
    ├── mirror-check.sh      # drift vs a vraj-ai/pi clone (read-only)
    └── mirror-sync.sh       # copy pi/ into that clone; never commits
```

`.cursor/skills/verify-agentic-harness-setup/` is the verification skill. It is
not copied by `sync.sh`.

## omp Roles

Copied from `vraj-ai/skills` `harness/omp/agent/`. Model and effort are unset;
assign those in omp.

**Invocation** (autoload the skill of the same name): `grill`, `issues`, `ship`,
`snapshot`, `goals`.

**Workers** (never spawn): `researcher`, `builder`, `reviewer`, `adversary`,
`small-task`.

Install live:

```bash
./scripts/sync.sh
```

That writes `omp/agent/` into `~/.omp/agent/agents/` (or `$OMP_AGENTS_DIR`).
Reload the omp Agents tab (Ctrl+R). `/setup-vskills` in the skills repo does
the same after it asks which harness you are on.

## OpenCode

Profiles live here under `opencode/`, matching `vraj-ai/skills`
`harness/opencode/`. `sync.sh` installs them to `~/.config/opencode/` (or
`$OPENCODE_CONFIG_DIR`).

Included: `goals`, `council`, contributor, cost-aware Gemini/DeepSeek, council
members, adversary, `/goal`.

Profiles that pin OpenCode Go: `contributor` and `council-glm`
(`opencode-go/glm-5.2`), `council-grok` and `council-adversary`
(`opencode-go/grok-4.5`). The other council profiles pin OpenRouter or
`openai/gpt-5.6-sol`. `goals` and `council` do not pin a model.

## Keep it up to date

The skills repo is the template source for omp Roles and OpenCode profiles.
This repo versions the snapshot and deploys it.

- **Repo → live** (after clone or bump):

  ```bash
  ./scripts/sync.sh
  ```

  Copies:

  - `opencode/` → `~/.config/opencode` (and `~/Work/skills/harness/opencode` if that clone exists)
  - `omp/agent/` → `~/.omp/agent/agents` (and `~/Work/skills/harness/omp/agent` if present)
  - `prime-agent/extensions/subagent` → `~/.prime/agent/extensions/subagent`
  - `prime-agent/agents` → `~/.prime/agent/agents`
  - `prime-agent/prompts` → `~/.prime/agent/prompts`

  It does not install `pi/`. Restart omp, OpenCode, or Prime Agent (`/reload`).

- **Skills or live → repo** (before you commit):

  ```bash
  ./scripts/capture.sh
  ```

  Prefers `~/Work/skills/harness/` when it exists, else the live config dirs.
  This writes into the repo that contains the script.

- **Pi mirror** (`github.com/vraj-ai/pi`):

  ```bash
  ./scripts/mirror-check.sh --mirror <clone>
  ./scripts/mirror-sync.sh --mirror <clone>    # copies files; does not commit or push
  ```

### Versioning

Bump `VERSION` when agents, Roles, or scripts change. SemVer: MAJOR breaking,
MINOR features, PATCH fixes.

## Prime Agent `@`-mention subagents

Installed via `~/.prime/agent/extensions/subagent`:

- Type `@` for an autocomplete picker of `~/.prime/agent/agents/*.md`.
- `@name <task>` delegates to that agent.
- `@a @b <task>` runs several in parallel.

See `prime-agent/extensions/subagent/README.md`.

omp is the client for `/grill` → `/issues` → `/ship`, or `/goals` → `/snapshot`.
Inside `ship`, multi-module work, a design fork, or an unknown cause runs
pstack poteto-mode (understand → design → build → verify → interrogate → ship).

## Current stack

Herdr fans out to Claude Code and pi, both on OpenCode Go. The other lanes are
the Devin CLI, Cursor cloud agents, and T3 Code with t3-pstack. pstack is set
up in Cursor with `/setup-pstack`. Details, including what this repo does not
install, are in [`CONTEXT/architecture.md`](CONTEXT/architecture.md).

## Pi

`pi/` installs into `~/.pi/agent` with `pi/install.sh`. See `pi/README.md` and
`pi/SETUP.md`. Its in-session Herdr extension (`pi/extensions/subagents`) is a
read-only subagent fleet. That is separate from the Herdr session fan-out above.
`pi/settings.example.json` still defaults to `openai-codex` / `gpt-5.6-sol`.

## Verify

```bash
.cursor/skills/verify-agentic-harness-setup/verify.sh all
```

The run uses a disposable `HOME` and a temporary mirror. It does not write to
the real home directory or commit the pi mirror.

## Notes

- No secrets. Keys stay in local auth stores.
- Do not treat `smol` / `task` / `advisor` as worker identities. Those are omp
  model aliases. Spawn the named Worker Roles instead.
