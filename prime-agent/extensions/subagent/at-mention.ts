/**
 * @-mention subagents (OpenCode-style)
 *
 * - Type "@" in the composer to get an autocomplete picker of every agent
 *   defined in ~/.prime/agent/agents/*.md (and project .prime/agent/agents/*.md).
 * - Submit "@name <task>" to deterministically delegate <task> to that agent:
 *   the input is transformed into an explicit directive to call the "subagent"
 *   tool in single mode, and the result is relayed back verbatim.
 * - Submit "@a @b <task>" to delegate the same task to several agents in
 *   parallel mode.
 *
 * Works with the "subagent" tool registered by ./tool.ts (same directory).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getAgentDir, parseFrontmatter } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem, AutocompleteProvider, AutocompleteSuggestions } from "@earendil-works/pi-tui";

interface AgentConfig {
	name: string;
	description: string;
	source: "user" | "project";
}

function loadAgentsFromDir(dir: string, source: "user" | "project"): AgentConfig[] {
	const agents: AgentConfig[] = [];
	if (!fs.existsSync(dir)) return agents;

	let entries: fs.Dirent[];
	try {
		entries = fs.readdirSync(dir, { withFileTypes: true });
	} catch {
		return agents;
	}

	for (const entry of entries) {
		if (!entry.name.endsWith(".md")) continue;
		if (!entry.isFile() && !entry.isSymbolicLink()) continue;

		const filePath = path.join(dir, entry.name);
		let content: string;
		try {
			content = fs.readFileSync(filePath, "utf-8");
		} catch {
			continue;
		}

		const { frontmatter } = parseFrontmatter<Record<string, string>>(content);
		if (!frontmatter.name || !frontmatter.description) continue;

		agents.push({
			name: frontmatter.name,
			description: frontmatter.description,
			source,
		});
	}

	return agents;
}

function isDirectory(p: string): boolean {
	try {
		return fs.statSync(p).isDirectory();
	} catch {
		return false;
	}
}

function findNearestProjectAgentsDir(cwd: string): string | null {
	let currentDir = cwd;
	while (true) {
		const candidate = path.join(currentDir, ".prime", "agent", "agents");
		if (isDirectory(candidate)) return candidate;

		const parentDir = path.dirname(currentDir);
		if (parentDir === currentDir) return null;
		currentDir = parentDir;
	}
}

function discoverAgents(cwd: string): AgentConfig[] {
	const userDir = path.join(getAgentDir(), "agents");
	const userAgents = loadAgentsFromDir(userDir, "user");
	const projectAgentsDir = findNearestProjectAgentsDir(cwd);
	const projectAgents = projectAgentsDir ? loadAgentsFromDir(projectAgentsDir, "project") : [];

	const agentMap = new Map<string, AgentConfig>();
	for (const agent of userAgents) agentMap.set(agent.name, agent);
	for (const agent of projectAgents) agentMap.set(agent.name, agent); // project overrides user

	return Array.from(agentMap.values());
}

export const DEFAULT_TASK =
	"Review the current conversation context and respond with your expert assessment.";

// Filler verbs that produce a meaningless task when they are all that remains
// after stripping mentions (e.g. "use @reviewer").
const FILLER_WORDS = new Set(["use", "ask", "get", "have", "make", "let", "check"]);

export function normalizeTask(raw: string): string {
	const trimmed = raw.trim();
	if (!trimmed) return DEFAULT_TASK;
	const words = trimmed.split(/\s+/);
	if (words.length === 1 && FILLER_WORDS.has(words[0].toLowerCase())) return DEFAULT_TASK;
	return trimmed;
}

export function extractMentions(text: string, byName: Map<string, AgentConfig>): string[] {
	const names: string[] = [];
	const re = /(?:^|\s)@([A-Za-z0-9_.-]+)/g;
	for (const m of text.matchAll(re)) {
		const name = m[1];
		if (byName.has(name) && !names.includes(name)) names.push(name);
	}
	return names;
}

export function stripMentions(text: string): string {
	return text.replace(/(?:^|\s)@([A-Za-z0-9_.-]+)/g, " ").replace(/\s+/g, " ").trim();
}

export function buildSingleDirective(name: string, task: string): string {
	return [
		`<@mention:${name}>`,
		`Use the "subagent" tool now in single mode.`,
		`Tool parameters: ${JSON.stringify({ agent: name, task })}`,
		`Call the tool, wait for it to finish, and relay the subagent's final output to the user verbatim. Do not summarize, truncate, or paraphrase it.`,
		`</@mention>`,
	].join("\n");
}

export function buildParallelDirective(names: string[], task: string): string {
	const tasks = names.map((agent) => ({ agent, task }));
	return [
		`<@mention:${names.join(",")}>`,
		`Use the "subagent" tool now in parallel mode.`,
		`Tool parameters: ${JSON.stringify({ tasks })}`,
		`Call the tool, wait for every agent to finish, and relay each subagent's final output to the user verbatim. Do not summarize, truncate, or paraphrase them.`,
		`</@mention>`,
	].join("\n");
}

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const agents = discoverAgents(ctx.cwd);
		const byName = new Map(agents.map((a) => [a.name, a]));

		ctx.ui.addAutocompleteProvider((current: AutocompleteProvider) => ({
			async getSuggestions(lines, cursorLine, cursorCol, options): Promise<AutocompleteSuggestions | null> {
				const line = lines[cursorLine] ?? "";
				const beforeCursor = line.slice(0, cursorCol);
				const match = beforeCursor.match(/(?:^|[ \t])@([^\s@]*)$/);
				if (!match) {
					return current.getSuggestions(lines, cursorLine, cursorCol, options);
				}

				const query = match[1] ?? "";
				const items: AutocompleteItem[] = agents
					.filter((a) => a.name.startsWith(query))
					.slice(0, 10)
					.map((a) => ({
						value: `@${a.name} `,
						label: `@${a.name}`,
						description: `${a.description} (${a.source})`,
					}));

				if (items.length === 0) {
					return current.getSuggestions(lines, cursorLine, cursorCol, options);
				}

				return { items, prefix: `@${query}` };
			},

			applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
				return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
			},

			shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
				return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
			},
		}));
	});

	pi.on("input", async (event, ctx) => {
		if (event.source !== "interactive") return { action: "continue" };
		if (event.images && event.images.length > 0) return { action: "continue" };

		const agents = discoverAgents(ctx.cwd);
		const byName = new Map(agents.map((a) => [a.name, a]));
		const names = extractMentions(event.text, byName);
		if (names.length === 0) return { action: "continue" };

		const task = normalizeTask(stripMentions(event.text));
		ctx.ui.notify(`→ delegating to @${names.join(", @")}`, "info");

		if (names.length === 1) {
			return { action: "transform", text: buildSingleDirective(names[0], task) };
		}
		return { action: "transform", text: buildParallelDirective(names, task) };
	});
}
