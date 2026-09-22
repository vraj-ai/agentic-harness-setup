/**
 * The active terminal theme, resolved to the dashboard's CSS token names.
 *
 * The page used to hard-code one theme's hex values, so switching themes left
 * the dashboard in the old palette. The tokens instead come from the theme the
 * agent dir names (settings.json `theme`), falling back to the documented
 * default theme, then to the theme shipped with this source tree. Nothing in
 * the CSS pipeline pins hex values.
 */

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export interface DashboardTokens {
  readonly bg: string;
  readonly panel: string;
  readonly surface: string;
  readonly border: string;
  readonly text: string;
  readonly muted: string;
  readonly dim: string;
  readonly accent: string;
  readonly cobalt: string;
  readonly mint: string;
  readonly amber: string;
  readonly red: string;
}

const DEFAULT_THEME = "cobalt-ink";

interface ThemeFile {
  readonly vars?: Record<string, string>;
  readonly colors?: Record<string, string>;
  readonly export?: Record<string, string>;
}

function readJson(file: string): ThemeFile | undefined {
  try {
    const raw: unknown = JSON.parse(readFileSync(file, "utf8"));
    if (raw && typeof raw === "object" && !Array.isArray(raw)) {
      return raw as ThemeFile;
    }
  } catch {
    // unreadable file: caller tries the next source
  }
  return undefined;
}

function tokensFromTheme(
  theme: ThemeFile | undefined,
): DashboardTokens | undefined {
  if (!theme) return undefined;
  const vars = theme.vars ?? {};
  const colors = theme.colors ?? {};
  const exports = theme.export ?? {};
  const resolve = (raw: unknown): string | undefined => {
    if (typeof raw !== "string") return undefined;
    if (raw.startsWith("#")) return raw;
    return vars[raw];
  };
  const tokens = {
    bg: resolve(exports.pageBg),
    panel: resolve(exports.cardBg),
    surface: resolve(exports.infoBg),
    border: resolve(colors.border),
    text: resolve(colors.text),
    muted: resolve(colors.muted),
    dim: resolve(colors.dim),
    accent: resolve(colors.accent),
    cobalt: resolve(colors.borderAccent),
    mint: resolve(colors.success),
    amber: resolve(colors.warning),
    red: resolve(colors.error),
  };
  for (const value of Object.values(tokens)) {
    if (value === undefined) return undefined;
  }
  return tokens as DashboardTokens;
}

function themeSources(agentDir: string): string[] {
  const sources: string[] = [];
  const settings = readJson(join(agentDir, "settings.json"));
  const named = (settings as Record<string, unknown> | undefined)?.theme;
  if (typeof named === "string" && named) {
    sources.push(join(agentDir, "themes", `${named}.json`));
  }
  sources.push(join(agentDir, "themes", `${DEFAULT_THEME}.json`));
  const here = dirname(fileURLToPath(import.meta.url));
  sources.push(join(here, "..", "..", "..", "themes", `${DEFAULT_THEME}.json`));
  return sources;
}

export function dashboardTokens(agentDir: string): DashboardTokens {
  for (const file of themeSources(agentDir)) {
    const tokens = tokensFromTheme(readJson(file));
    if (tokens) return tokens;
  }
  throw new Error(
    `no readable shipped theme for the ${DEFAULT_THEME} fallback`,
  );
}
