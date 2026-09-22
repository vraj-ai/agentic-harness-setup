export const glyphs = {
  running: "◉",
  done: "✓",
  failed: "✗",
  killed: "·",
  idle: "·",
} as const;

export type GlyphState = keyof typeof glyphs;

export function glyphOf(state: string) {
  return glyphs[state as GlyphState] ?? glyphs.idle;
}

export const marker = "❯ ";
export const separator = " · ";
export const writeOwn = "✎";

export function hint(...items: string[]) {
  return items.join(separator);
}

export const BOX = {
  tl: "╭",
  tr: "╮",
  bl: "╰",
  br: "╯",
  h: "─",
  v: "│",
} as const;

export function fmtTokens(n: number) {
  const trim = (s: string) => s.replace(/\.0$/, "");
  if (n < 1000) return `${Math.round(n)}`;
  if (n < 1e6) return trim((n / 1e3).toFixed(1)) + "k";
  if (n < 1e9) return trim((n / 1e6).toFixed(1)) + "M";
  return trim((n / 1e9).toFixed(1)) + "B";
}

export const emptyState = (thing: string) => `(no ${thing} yet)`;
export const emptyReport = "no data in this range";
