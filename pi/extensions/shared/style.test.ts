import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  BOX,
  emptyReport,
  emptyState,
  fmtTokens,
  glyphOf,
  glyphs,
  hint,
  marker,
  separator,
  writeOwn,
} from "./style.ts";

test("kit exports own the view grammar", () => {
  assert.equal(glyphs.running, "◉");
  assert.equal(glyphs.done, "✓");
  assert.equal(glyphs.failed, "✗");
  assert.equal(glyphs.killed, "·");
  assert.equal(glyphs.idle, "·");
  assert.equal(glyphOf("done"), "✓");
  assert.equal(glyphOf("unknown"), "·");
  assert.equal(marker, "❯ ");
  assert.equal(separator, " · ");
  assert.equal(writeOwn, "✎");
  assert.deepEqual(
    { ...BOX },
    { tl: "╭", tr: "╮", bl: "╰", br: "╯", h: "─", v: "│" },
  );
  assert.equal(emptyState("output"), "(no output yet)");
  assert.equal(emptyReport, "no data in this range");
});

test("hint joins with the shared separator", () => {
  assert.equal(
    hint("esc close", "enter open diff"),
    "esc close · enter open diff",
  );
});

test("fmtTokens uses one decimal with unified suffixes", () => {
  assert.equal(fmtTokens(999), "999");
  assert.equal(fmtTokens(900_000), "900k");
  assert.equal(fmtTokens(1_000_000), "1M");
  assert.equal(fmtTokens(1_500_000), "1.5M");
  assert.equal(fmtTokens(1_234_567), "1.2M");
});

const EXT_DIR = join(dirname(fileURLToPath(import.meta.url)), "..");

function tsFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(dir)) {
    if (entry === "node_modules" || entry === ".git" || entry === "shared")
      continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) out.push(...tsFiles(full));
    else if (entry.endsWith(".ts")) out.push(full);
  }
  return out;
}

const FORBIDDEN = [
  "✗",
  "×",
  "❯",
  "›",
  "■",
  "◉",
  "✓",
  "✦",
  "✎",
  " • ",
  "┌",
  "┐",
  "└",
  "┘",
];

test("view sources own no glyph, marker, separator, or box literal", () => {
  const offenders: string[] = [];
  for (const file of tsFiles(EXT_DIR)) {
    const text = readFileSync(file, "utf8");
    for (const lit of FORBIDDEN) {
      if (text.includes(lit)) offenders.push(`${file} ${JSON.stringify(lit)}`);
    }
  }
  assert.deepEqual(offenders, []);
});
