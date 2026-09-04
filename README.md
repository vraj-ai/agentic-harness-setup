# agentic-harness-setup

Versioned machine harness for the coding agents on this account. It snapshots
the **omp Roles**, **OpenCode** profiles, and the **Prime Agent** `@`-mention
harness, plus sync scripts so live installs stay aligned with
[vraj-ai/skills](https://github.com/vraj-ai/skills).

Current version: **0.5.0** (see [`VERSION`](VERSION)).

Skills stay portable. This repo is the machine overlay: Role files, OpenCode
agents, Prime Agent extensions. Workflow skills themselves live in `vskills`.

## Layout

```
agentic-harness-setup/
├── VERSION
├── README.md
├── omp/agent/              # Invocation + Worker Role templates
├── opencode/               # OpenCode agents + slash commands
│   ├── agent/
│   └── command/
├── claude-code/agents/
├── prime-agent/            # Prime Agent @-mention harness
│   ├── extensions/subagent/
│   ├── agents/
│   └── prompts/
├── pi/                     # Vraj Pi; launched with `pi`
├── pitest/                 # isolated amosblomqvist pi-config + learn; launched with `pitest`
└── scripts/
    ├── sync.sh             # repo -> live installs
    └── capture.sh          # skills/live -> repo
```

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
`$OPENCODE_CONFIG_DIR`), not into a top-level `skills/opencode/` tree. That
path is gone.

Included: `goals`, `council`, contributor, cost-aware Gemini/DeepSeek, council
members, adversary, `/goal`.

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

  Restart omp, OpenCode, or Prime Agent (`/reload`).

- **Skills or live → repo** (before you commit):

  ```bash
  ./scripts/capture.sh
  ```

  Prefers `~/Work/skills/harness/` when it exists, else the live config dirs.

### Versioning

Bump `VERSION` when agents, Roles, or scripts change. SemVer: MAJOR breaking,
MINOR features, PATCH fixes.

## Prime Agent `@`-mention subagents

Installed via `~/.prime/agent/extensions/subagent`:

- Type `@` for an autocomplete picker of `~/.prime/agent/agents/*.md`.
- `@name <task>` delegates to that agent.
- `@a @b <task>` runs several in parallel.

See `prime-agent/extensions/subagent/README.md`.

Prime Agent still ships the older council/contributor set. omp is the author's
client for `/grill` → `/issues` → `/ship` or `/goals` → `/snapshot`.

## Notes

- No secrets. Keys stay in local auth stores.
- Do not treat `smol` / `task` / `advisor` as worker identities. Those are omp
  model aliases. Spawn the named Worker Roles instead.

## Pi configurations

`pi/` is the full Prime Agent configuration previously hosted as
`vraj-ai/Pi-Setup`. See `pi/README.md` and `pi/SETUP.md`.

`pitest/` combines `amosblomqvist/pi-config` and `amosblomqvist/learn` in an
isolated config. Use `pi` for the existing setup and `pitest` for this test setup.
