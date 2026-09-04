/**
 * herdr surface layer — the Herdr pane backend for interactive subagents.
 *
 * Drop-in replacement for tmux.ts: everything the extension does to a pane
 * goes through the small API in this file (create/split a pane, type a
 * command into it, read its screen, close it, poll for exit), so index.ts
 * stays backend-agnostic and testable.
 *
 * Mapping tmux -> herdr:
 * - `$TMUX_PANE` (parent anchor)      -> `$HERDR_PANE_ID`
 * - `tmux split-window -d -h -t <p>`  -> `herdr pane split --pane <p> --direction right --no-focus`
 * - `tmux send-keys -t <p> -l <cmd>`  -> `herdr pane send-text <p> <cmd>`
 * - `tmux send-keys -t <p> Enter`     -> `herdr pane send-keys <p> Enter`
 * - `tmux capture-pane -p -t <p>`     -> `herdr pane read <p> --lines <n>` (plain text on stdout)
 * - `tmux kill-pane -t <p>`           -> `herdr pane close <p>`
 * - `tmux select-layout ...`          -> not needed; Herdr tiles panes itself
 *
 * Panes are identified by Herdr pane ids (e.g. `w12:p4`). Splits always
 * target the parent pi's pane (`$HERDR_PANE_ID`) with `--no-focus`, so new
 * panes follow the agent rather than the user's focus and never steal it.
 * See https://github.com/HazAT/pi-interactive-subagents/issues/12
 */
import { execFile, execFileSync } from "node:child_process";
import { promisify } from "node:util";
import { existsSync, readFileSync, rmSync, writeFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

const execFileAsync = promisify(execFile);

// ── Availability ──

const commandAvailability = new Map<string, boolean>();

function hasCommand(command: string): boolean {
  if (commandAvailability.has(command)) {
    return commandAvailability.get(command)!;
  }

  let available = false;
  try {
    execFileSync("sh", ["-c", `command -v ${command}`], { stdio: "ignore" });
    available = true;
  } catch {
    available = false;
  }

  commandAvailability.set(command, available);
  return available;
}

/**
 * True when running inside Herdr with the herdr binary on PATH.
 * `HERDR_ENV=1` is set by Herdr in every process it spawns.
 */
export function isHerdrAvailable(): boolean {
  const env = process.env.HERDR_ENV?.trim().toLowerCase();
  return (env === "1" || env === "true") && hasCommand("herdr");
}

export function isMuxAvailable(): boolean {
  return isHerdrAvailable();
}

export function muxSetupHint(): string {
  return "Run pi inside Herdr (`herdr --session <name>` or attach with `herdr`). Subagents spawn as Herdr panes.";
}

function requireHerdr(): void {
  if (!isHerdrAvailable()) {
    throw new Error(`Herdr is required for subagents. ${muxSetupHint()}`);
  }
}

// ── herdr CLI plumbing ──

interface HerdrSplitResult {
  pane: { pane_id: string };
}

/** Run a herdr subcommand that returns the standard JSON envelope; unwrap `result`. */
function herdrJSON<T>(args: string[]): T {
  const out = execFileSync("herdr", args, { encoding: "utf8" });
  return (JSON.parse(out) as { result: T }).result;
}

async function herdrJSONAsync<T>(args: string[]): Promise<T> {
  const { stdout } = await execFileAsync("herdr", args, { encoding: "utf8" });
  return (JSON.parse(stdout) as { result: T }).result;
}

/** The parent pi's pane id — the stable split anchor. Survives subagent panes closing. */
function parentPane(): string | undefined {
  return process.env.HERDR_PANE_ID?.trim() || undefined;
}

// ── Shell helpers ──

export function shellEscape(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

// ── Surface primitives ──

/**
 * Create a new pane for a subagent: a right split off the parent pi's pane,
 * so new panes follow the agent rather than the user's focus.
 *
 * Returns the new pane id (e.g. `w12:p4`).
 */
export function createSurface(name: string): string {
  void name; // Herdr panes are not named at split time; the pi process inside shows its own title.
  return createSurfaceSplit(name, "right", parentPane());
}

/**
 * Create a new split in the given direction from an optional source pane.
 * Herdr only supports `right` and `down` splits, so `left` maps to `right`
 * and `up` maps to `down` — the caller always gets a fresh pane, just on the
 * supported side.
 * Returns the new pane id (e.g. `w12:p4`).
 */
export function createSurfaceSplit(
  name: string,
  direction: "left" | "right" | "up" | "down",
  fromSurface?: string,
): string {
  void name;
  requireHerdr();

  const herdrDirection = direction === "up" || direction === "down" ? "down" : "right";
  const args = ["pane", "split", "--direction", herdrDirection, "--no-focus"];
  const anchor = fromSurface ?? parentPane();
  if (anchor) {
    args.push("--pane", anchor);
  } else {
    args.push("--current");
  }

  const result = herdrJSON<HerdrSplitResult>(args);
  const pane = result?.pane?.pane_id;
  if (!pane || typeof pane !== "string") {
    throw new Error(`Unexpected herdr pane split output: ${JSON.stringify(result)}`);
  }
  return pane;
}

/**
 * Send a command string to a pane and execute it.
 * Sent literally (`send-text`) so special characters are not interpreted as
 * keys, then submitted with Enter — mirroring `tmux send-keys -l` + Enter.
 */
export function sendCommand(surface: string, command: string): void {
  requireHerdr();
  execFileSync("herdr", ["pane", "send-text", surface, command], { encoding: "utf8" });
  execFileSync("herdr", ["pane", "send-keys", surface, "Enter"], { encoding: "utf8" });
}

/**
 * Send a long command to a pane by writing it to a script file first.
 * This avoids terminal line-wrapping issues that break commands exceeding the
 * pane's column width when sent character-by-character via sendCommand.
 *
 * By default the script is written to a temp directory, but callers can pass a
 * stable path (for example under session artifacts) so the exact invocation is
 * preserved for debugging.
 *
 * Returns the script path.
 */
export function sendLongCommand(
  surface: string,
  command: string,
  options?: { scriptPath?: string; scriptPreamble?: string },
): string {
  const scriptPath =
    options?.scriptPath ??
    join(
      tmpdir(),
      "pi-subagent-scripts",
      `cmd-${Date.now()}-${Math.random().toString(16).slice(2, 8)}.sh`,
    );
  mkdirSync(dirname(scriptPath), { recursive: true });

  const scriptParts = ["#!/bin/bash"];
  if (options?.scriptPreamble) {
    scriptParts.push(options.scriptPreamble.trimEnd());
  }
  scriptParts.push(command);

  writeFileSync(scriptPath, scriptParts.join("\n") + "\n", {
    mode: 0o755,
  });
  sendCommand(surface, `bash ${shellEscape(scriptPath)}`);
  return scriptPath;
}

/**
 * Read the screen contents of a pane (sync).
 * `herdr pane read` prints the terminal snapshot as plain text on stdout.
 */
export function readScreen(surface: string, lines = 50): string {
  requireHerdr();
  return execFileSync("herdr", ["pane", "read", surface, "--lines", `${Math.max(1, lines)}`], {
    encoding: "utf8",
  });
}

/**
 * Read the screen contents of a pane (async).
 */
export async function readScreenAsync(surface: string, lines = 50): Promise<string> {
  requireHerdr();
  const { stdout } = await execFileAsync(
    "herdr",
    ["pane", "read", surface, "--lines", `${Math.max(1, lines)}`],
    { encoding: "utf8" },
  );
  return stdout;
}

/**
 * Close a pane.
 */
export function closeSurface(surface: string): void {
  requireHerdr();
  execFileSync("herdr", ["pane", "close", surface], { encoding: "utf8" });
}

// ── Exit polling ──

export interface PollResult {
  /** How the subagent exited */
  reason: "done" | "sentinel" | "error";
  /** Shell exit code (from sentinel). 0 for file-based exits. */
  exitCode: number;
  /** Error message if reason is "error" (auto-retry exhausted, provider overload, etc.) */
  errorMessage?: string;
}

/**
 * Interpret an `.exit` sidecar payload (written by the error path in
 * subagent-done.ts). Centralized so both the fast and slow paths in
 * pollForExit decode the payload the same way. Clean completions write no
 * sidecar and are detected via the terminal sentinel instead.
 *
 * Note: ask_question does NOT write a `.exit` sidecar — it keeps the session
 * open and signals the parent via a separate `.ask` file (see deliverPendingQuestion).
 */
function interpretExitSidecar(data: any): PollResult {
  if (data?.type === "error") {
    const errorMessage =
      typeof data.errorMessage === "string" && data.errorMessage.trim() !== ""
        ? data.errorMessage
        : "Subagent exited with stopReason=error (no errorMessage in sidecar).";
    return { reason: "error", exitCode: 1, errorMessage };
  }
  return { reason: "done", exitCode: 0 };
}

export const __pollForExitTest__ = { interpretExitSidecar };

/**
 * Poll until the subagent exits. Checks for a `.exit` sidecar file first
 * (written by the error path), falling back to the terminal sentinel for
 * clean-completion and crash detection.
 */
export async function pollForExit(
  surface: string,
  signal: AbortSignal,
  options: {
    interval: number;
    sessionFile?: string;
    sentinelFile?: string;
    onTick?: (elapsed: number) => void;
  },
): Promise<PollResult> {
  const start = Date.now();

  for (;;) {
    if (signal.aborted) {
      throw new Error("Aborted while waiting for subagent to finish");
    }

    // Fast path: check for .exit sidecar file (written by the error path)
    if (options.sessionFile) {
      try {
        const exitFile = `${options.sessionFile}.exit`;
        if (existsSync(exitFile)) {
          const data = JSON.parse(readFileSync(exitFile, "utf-8"));
          rmSync(exitFile, { force: true });
          return interpretExitSidecar(data);
        }
      } catch {}
    }

    // Check Claude sentinel file (written by plugin Stop hook)
    if (options.sentinelFile) {
      try {
        if (existsSync(options.sentinelFile)) {
          return { reason: "sentinel", exitCode: 0 };
        }
      } catch {}
    }

    // Slow path: read terminal screen for sentinel (crash detection)
    try {
      const screen = await readScreenAsync(surface, 5);
      const match = screen.match(/__SUBAGENT_DONE_(\d+)__/);
      if (match) {
        return { reason: "sentinel", exitCode: parseInt(match[1], 10) };
      }
    } catch {
      // Surface may have been destroyed — check if .exit file appeared in the meantime
      if (options.sessionFile) {
        try {
          const exitFile = `${options.sessionFile}.exit`;
          if (existsSync(exitFile)) {
            const data = JSON.parse(readFileSync(exitFile, "utf-8"));
            rmSync(exitFile, { force: true });
            return interpretExitSidecar(data);
          }
        } catch {}
      }
    }

    const elapsed = Math.floor((Date.now() - start) / 1000);
    options.onTick?.(elapsed);

    await new Promise<void>((resolve, reject) => {
      if (signal.aborted) return reject(new Error("Aborted"));
      const timer = setTimeout(() => {
        signal.removeEventListener("abort", onAbort);
        resolve();
      }, options.interval);
      function onAbort() {
        clearTimeout(timer);
        reject(new Error("Aborted"));
      }
      signal.addEventListener("abort", onAbort, { once: true });
    });
  }
}
