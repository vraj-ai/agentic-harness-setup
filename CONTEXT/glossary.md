# Glossary

- **omp Role.** A markdown file in `omp/agent/` installed to `~/.omp/agent/agents`. Invocation Roles (`grill`, `issues`, `ship`, `snapshot`, `goals`) autoload the skill of the same name from vraj-ai/skills. Worker Roles do not spawn.
- **OpenCode Go.** Provider id `opencode-go` on profiles in `opencode/agent/` and `prime-agent/agents/`. The operating stack runs the Herdr Claude Code and pi arms on this provider.
- **Herdr (session host).** The fan-out the captain uses to run Claude Code and pi. This repo does not ship that CLI.
- **Herdr (Pi extension).** `pi/extensions/subagents`. Read-only subagents inside one Pi session. Not the session host.
- **Prime Agent.** The `@`-mention harness under `prime-agent/`, installed to `~/.prime/agent`.
- **Pi.** The terminal agent configured by `pi/` and installed to `~/.pi/agent`.
- **pstack.** Cursor plugin. `/poteto-mode` is the inner engineering loop. `/setup-pstack` writes `~/.cursor/rules/pstack-models.mdc`.
- **t3-pstack.** The same loop inside T3 Code, invoked as `/t3-pstack:<name>` or `$t3-pstack:<name>`. It is not installed by this repo.
- **verify-agentic-harness-setup.** The project-local skill that proves sync, capture, the pi mirror, and a Pi install dry-run.
