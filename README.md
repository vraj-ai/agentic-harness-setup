# agentic-harness-setup

Versioned, source-of-truth harness setup for the AI coding agents used on this
machine. It centralises the **OpenCode** subagent setup and the **Prime Agent**
harness (the OpenCode-style `@`-mention subagent extension + agent profiles +
workflow prompts), plus sync scripts so both live installs stay up to date.

Current version: **0.1.0** (see [`VERSION`](VERSION)).

## Layout

```
agentic-harness-setup/
├── VERSION                     # semantic version of this harness
├── README.md
├── opencode/                   # OpenCode setup (from ~/Work/skills/opencode)
│   ├── agent/                  #   subagent profile definitions (*.md)
│   └── command/                #   slash commands
├── prime-agent/                # Prime Agent harness (from ~/.prime/agent)
│   ├── extensions/subagent/    #   @-mention subagent extension + tool
│   ├── agents/                 #   invocable agent profiles (ported from opencode)
│   └── prompts/                #   workflow prompt templates (/implement etc.)
└── scripts/
    ├── sync.sh                 # repo -> live installs (deploy)
    └── capture.sh              # live installs -> repo (pull edits back)
```

## Keep it up to date

The repo is the **source of truth**. Two directions:

- **Deploy repo → live installs** (after a clone/update or version bump):
  ```bash
  ./scripts/sync.sh
  ```
  This copies:
  - `opencode/` → `~/Work/skills/opencode`
  - `prime-agent/extensions/subagent` → `~/.prime/agent/extensions/subagent`
  - `prime-agent/agents` → `~/.prime/agent/agents`
  - `prime-agent/prompts` → `~/.prime/agent/prompts`

  After syncing the Prime Agent pieces, restart `prime-agent` or run `/reload`.

- **Pull live edits back → repo** (before committing changes you made directly
  in the live installs):
  ```bash
  ./scripts/capture.sh
  ```

### Versioning

- Bump `VERSION` whenever you change the harness (e.g. new agents, changed
  prompts, extension tweaks). Keep it in sync with both `opencode/` and
  `prime-agent/` so a single tag describes the whole setup.
- Suggest following [SemVer](https://semver.org/): bump MAJOR for breaking
  changes, MINOR for new features, PATCH for fixes.

## Prime Agent `@`-mention subagents

Installed globally by this repo (via `~/.prime/agent/extensions/subagent`):

- Type `@` in the prime-agent composer for an autocomplete picker of every
  agent in `~/.prime/agent/agents/*.md`.
- `@name <task>` delegates `<task>` to that agent (isolated subprocess, result
  relayed verbatim).
- `@a @b <task>` runs several agents in parallel.
- Plain delegation also works ("use contributor to …"), plus `/implement`,
  `/scout-and-plan`, `/implement-and-review` workflow templates.

See `prime-agent/extensions/subagent/README.md` for details and caveats.

## Agents

Ported from `opencode/agent/*.md` (system prompts preserved verbatim):
`contributor`, `council`, `council-adversary`, `council-glm`, `council-grok`,
`council-kimi`, `council-qwen`, `council-sol`, `goals`.

## Notes

- No secrets are stored here — only agent definitions, prompts, and extension
  code. Keep API keys out (they live in the local auth stores).
- The OpenCode setup here mirrors `~/Work/skills/opencode`; the Prime Agent
  setup mirrors `~/.prime/agent`. Use the scripts to keep all three in sync.
