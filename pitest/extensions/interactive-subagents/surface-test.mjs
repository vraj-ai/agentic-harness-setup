#!/usr/bin/env node
// Surface-level test for the herdr backend — real Herdr panes, no LLM calls.
// Run inside Herdr: HERDR_ENV=1 HERDR_PANE_ID=<id> node --experimental-strip-types surface-test.mjs
import assert from "node:assert/strict";
import {
  isMuxAvailable,
  isHerdrAvailable,
  muxSetupHint,
  createSurface,
  createSurfaceSplit,
  sendCommand,
  sendLongCommand,
  readScreen,
  readScreenAsync,
  closeSurface,
  shellEscape,
} from "./herdr.ts";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const SHELL_READY_MS = Number(process.env.PI_SUBAGENT_SHELL_READY_DELAY_MS ?? "3000");
let pass = 0;
async function check(name, fn) {
  try {
    await fn();
    pass++;
    console.log(`ok - ${name}`);
  } catch (e) {
    console.error(`FAIL - ${name}: ${e.message}`);
    process.exitCode = 1;
  }
}
const marker = () => Math.random().toString(36).slice(2, 10);

assert.equal(isHerdrAvailable(), true, "herdr should be available in this env");
assert.equal(isMuxAvailable(), true);
console.log("hint:", muxSetupHint());
assert.equal(shellEscape("a'b"), "'a'\\''b'");

await check("create + send + read + close", async () => {
  const s = createSurface("test-echo");
  assert.match(s, /^w\d+:p[0-9A-Z]+$/, `pane id shape, got ${s}`);
  try {
    await sleep(SHELL_READY_MS);
    const m = marker();
    sendCommand(s, `echo "MARKER_${m}"`);
    let screen = "";
    const start = Date.now();
    while (Date.now() - start < 20_000) {
      screen = readScreen(s, 50);
      if (screen.includes(`MARKER_${m}`)) break;
      await sleep(1000);
    }
    assert.ok(screen.includes(`MARKER_${m}`), `marker missing:\n${screen}`);
  } finally {
    closeSurface(s);
  }
});

await check("special chars survive literally", async () => {
  const s = createSurface("test-escape");
  try {
    await sleep(SHELL_READY_MS);
    const m = marker();
    sendCommand(s, `echo 'SPEC_${m}_$HOME_"quotes"_done'`);
    await sleep(3000);
    const screen = readScreen(s, 50);
    assert.ok(screen.includes(`SPEC_${m}`), `marker missing:\n${screen}`);
    assert.ok(screen.includes("$HOME"), `literal $HOME missing:\n${screen}`);
  } finally {
    closeSurface(s);
  }
});

await check("long command via script file", async () => {
  const s = createSurface("test-long");
  try {
    await sleep(SHELL_READY_MS);
    const m = marker();
    sendLongCommand(s, `echo "LONG_${m}_${"X".repeat(500)}_END"`);
    let screen = "";
    const start = Date.now();
    while (Date.now() - start < 20_000) {
      screen = await readScreenAsync(s, 50);
      if (screen.includes("_END")) break;
      await sleep(1000);
    }
    assert.ok(screen.includes(`LONG_${m}`), `start missing`);
    assert.ok(screen.includes("_END"), `end missing (truncated?)`);
  } finally {
    closeSurface(s);
  }
});

await check("split directions map (left->right, up->down)", async () => {
  const a = createSurfaceSplit("test-left", "left");
  const b = createSurfaceSplit("test-up", "up", a);
  try {
    assert.match(a, /^w\d+:p[0-9A-Z]+$/);
    assert.match(b, /^w\d+:p[0-9A-Z]+$/);
    assert.notEqual(a, b);
  } finally {
    closeSurface(b);
    closeSurface(a);
  }
});

await check("new split does not take focus", async () => {
  const { execFileSync } = await import("node:child_process");
  const s = createSurface("test-focus");
  try {
    const panes = JSON.parse(
      execFileSync("herdr", ["pane", "list"], { encoding: "utf8" }),
    ).result.panes;
    assert.equal(panes.find((pane) => pane.pane_id === s)?.focused, false);
  } finally {
    closeSurface(s);
  }
});

console.log(`\n${pass} surface tests passed${process.exitCode ? " (WITH FAILURES)" : ""}`);
