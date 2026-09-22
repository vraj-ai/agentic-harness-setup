import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const themesDir = join(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "..",
  "themes",
);

const HEX = /^#[0-9a-fA-F]{6}$/;

/**
 * Guards every shipped theme: a var must be a literal hex colour, and every
 * `colors`/`export` entry must be either a literal hex colour or the name of a
 * declared var. A typo'd hex (the kind that renders as a black smear at
 * runtime) fails here instead of in the terminal.
 */
test("every shipped theme resolves to real colours", () => {
  const files = readdirSync(themesDir).filter((name) => name.endsWith(".json"));
  assert.ok(files.length > 0, "no themes found");

  for (const file of files) {
    const theme = JSON.parse(readFileSync(join(themesDir, file), "utf8"));
    const where = (key: string) => `${file}:${key}`;

    assert.equal(
      theme.name,
      file.replace(/\.json$/, ""),
      `${file}: name must match filename`,
    );

    const vars: Record<string, unknown> = theme.vars ?? {};
    for (const [key, value] of Object.entries(vars)) {
      assert.match(String(value), HEX, where(`vars.${key}`));
    }

    for (const section of ["colors", "export"] as const) {
      for (const [key, value] of Object.entries(theme[section] ?? {})) {
        const text = String(value);
        const resolved = text.startsWith("#")
          ? HEX.test(text)
          : Object.hasOwn(vars, text);
        assert.ok(resolved, `${where(`${section}.${key}`)} = ${text}`);
      }
    }
  }
});

test("every shipped theme declares the same schema authority and full colour set", () => {
  const SCHEMA_URL =
    "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";

  // The token set the upstream theme schema declares under `colors` (2026-09
  // schema). A shipped theme missing one of these keys renders runtime
  // fallbacks of smoke-grey defaults instead of the palette's voice.
  const REQUIRED_COLORS = [
    "accent",
    "border",
    "borderAccent",
    "borderMuted",
    "success",
    "error",
    "warning",
    "muted",
    "dim",
    "text",
    "thinkingText",
    "selectedBg",
    "scrollbarTrack",
    "scrollbarThumb",
    "searchMatchBg",
    "searchMatchText",
    "userMessageBg",
    "userMessageText",
    "customMessageBg",
    "customMessageText",
    "customMessageLabel",
    "toolPendingBg",
    "toolSuccessBg",
    "toolErrorBg",
    "toolTitle",
    "toolOutput",
    "mdHeading",
    "mdLink",
    "mdLinkUrl",
    "mdCode",
    "mdCodeBlock",
    "mdCodeBlockBorder",
    "mdQuote",
    "mdQuoteBorder",
    "mdHr",
    "mdListBullet",
    "toolDiffAdded",
    "toolDiffRemoved",
    "toolDiffContext",
    "syntaxComment",
    "syntaxKeyword",
    "syntaxFunction",
    "syntaxVariable",
    "syntaxString",
    "syntaxNumber",
    "syntaxType",
    "syntaxOperator",
    "syntaxPunctuation",
    "thinkingOff",
    "thinkingMinimal",
    "thinkingLow",
    "thinkingMedium",
    "thinkingHigh",
    "thinkingXhigh",
    "thinkingMax",
    "bashMode",
  ];

  const files = readdirSync(themesDir).filter((name) => name.endsWith(".json"));
  const read = (name: string) =>
    JSON.parse(readFileSync(join(themesDir, name), "utf8"));

  const schemas = files.map((file) => read(file).$schema);
  assert.equal(
    new Set(schemas).size,
    1,
    `every theme must declare the same $schema: got ${schemas.join(", ")}`,
  );
  schemas.forEach((url) => assert.equal(url, SCHEMA_URL));

  for (const name of files) {
    const theme = read(name);
    assert.equal(theme.name, name.replace(/\.json$/, ""));
    for (const key of REQUIRED_COLORS) {
      assert.ok(
        Object.hasOwn(theme.colors ?? {}, key),
        `${name} is missing the colors.${key} token`,
      );
    }
  }
});
