# @-mention subagents (OpenCode-style) — global install

This is a **global** Prime Agent setup (installed under `~/.prime/agent`, no
project files touched). It gives you OpenCode-style `@agent` subagent mentions
plus the official file-defined subagent tool.

## What was installed

```
~/.prime/agent/extensions/subagent/
  index.ts        composer: registers tool + @-mention behavior
  tool.ts         official "subagent" tool (single / parallel / chain modes)
  agents.ts       agent-profile discovery (user + project)
  at-mention.ts   @-mention autocomplete picker + input transform
~/.prime/agent/agents/*.md          agent profiles (ported from ~/Work/skills/opencode/agent)
~/.prime/agent/prompts/*.md         workflow prompt templates (/implement etc.)
```

## Usage

1. Restart `prime-agent` (or type `/reload` in the TUI).
2. Type `@` in the composer — a picker lists every agent with its description
   (from `~/.prime/agent/agents/*.md`).
3. Submit `@name <task>` to delegate:

```
@contributor add input validation to the session store
```

   The main agent calls the `subagent` tool with that agent + task, streams the
   run, and relays the result verbatim.

4. `@a @b <task>` delegates the same task to multiple agents in parallel.

5. Plain-language delegation also works (the tool is available to the model):
   "Use scout to find the auth code".

6. Workflow templates:
   `/implement <query>` — scout → planner → worker
   `/scout-and-plan <query>` — scout → planner
   `/implement-and-review <query>` — worker → reviewer → worker

## Agents (ported from ~/Work/skills/opencode/agent)

| agent | model | tools |
|---|---|---|
| contributor | opencode-go/glm-5.2 | bash, edit |
| council-adversary | opencode-go/grok-4.5 | bash |
| council-glm | opencode-go/glm-5.2 | bash |
| council-grok | opencode-go/grok-4.5 | bash |
| council-kimi | openrouter/moonshotai/kimi-k3 | bash |
| council-qwen | openrouter/qwen/qwen3.8-max | bash |
| council-sol | openai/gpt-5.6-sol | bash |
| council | (default model) | bash |
| goals | (default model) | bash, edit |

System prompts are preserved verbatim from the OpenCode setup. `council` and
`goals` were `mode: primary` in OpenCode; here they are invocable profiles too.

## Notes / limitations

- Prime Agent has no OpenCode-style per-permission system. The closest mapping
  is the `tools:` allowlist (`bash`, `edit`, `ipython`). Read-only intent is
  enforced by each agent's system prompt (kept verbatim). Adjust `tools:` in
  `~/.prime/agent/agents/*.md` if you want tighter/looser tooling.
- `@` mentions only fire for *known* agent names (typed @decorator, emails,
  etc. pass through untouched). Mentions only transform interactive input.
- Project-local agents (`.prime/agent/agents/*.md`) are discoverable in the
  picker with a `(project)` badge and override user agents of the same name,
  but the mention transform defaults to the global/user set; the tool only
  loads project agents with `agentScope: "both"` (and prompts for confirmation).
- The `subagent` tool spawns a separate `prime-agent` process per invocation
  (isolated context, streamed output, usage stats). It is different from RLM
  recursive children (`rlm()` from IPython) — this setup mirrors OpenCode's
  file-defined subagent model.

## Managing

- Add an agent: drop `name.md` (YAML frontmatter `name`/`description`/`model`/
  `tools`, body = system prompt) into `~/.prime/agent/agents/`, then `/reload`.
- Remove: delete the file, then `/reload`.
- Disable entirely: delete `~/.prime/agent/extensions/subagent/` and `/reload`.

## Verification status (2026-08-11)

- ✅ Extension loads: `prime-agent` auto-discovers `~/.prime/agent/extensions/subagent/index.ts`
  (composer + tool + at-mention + agents) without load errors.
- ✅ `@`-mention logic unit-tested (single, trailing, parallel, email/false-positive
  filtering, filler-verb and bare-mention handling) — 7/7 cases pass.
- ✅ Agent discovery: all 9 profiles resolve from `~/.prime/agent/agents`.
- ⏳ Live end-to-end (main agent → `subagent` tool → subprocess agent → relay) not yet
  exercised this session: the machine's DNS resolver is currently unhealthy
  (`scutil --dns` empty; node/curl can't resolve, though `dig`/`nslookup` work), so
  model calls can't complete. Re-run once DNS is back:
  `prime-agent -e ~/.prime/agent/extensions/subagent -p "Use the subagent tool: agent=test task='reply hello'"`

## Caveats

- Prime Agent has no OpenCode-style per-permission system; `tools:` is a coarse
  allowlist (`bash`, `edit`, `ipython`). Read-only intent lives in each agent's
  system prompt (kept verbatim from `~/Work/skills/opencode/agent`).
- Models that rely on OAuth-only providers (e.g. `openai/gpt-5.6-sol` for
  `council-sol`, `anthropic/*`) may fail in the standalone subprocess if token
  refresh requires the daemon — verify once network is healthy. Agents using
  `opencode-go/*` or `openrouter/*` use API keys and should work.
