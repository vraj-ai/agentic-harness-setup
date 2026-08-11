/**
 * Subagent extension (composer)
 *
 * - ./tool.ts      registers the "subagent" tool (single / parallel / chain
 *                  delegation to file-defined agent profiles)
 * - ./at-mention.ts adds OpenCode-style "@name" mentions: autocomplete picker
 *                  + input transform that routes the task to the named agent.
 */
import tool from "./tool.js";
import atMention from "./at-mention.js";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI): void {
	tool(pi);
	atMention(pi);
}
