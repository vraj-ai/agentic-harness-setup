import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { glyphs, separator } from "./style.ts";

type Theme = ExtensionContext["ui"]["theme"];

interface ActivityCounts {
  running: number;
  done: number;
  failed: number;
}

export function formatActivityStatus(
  theme: Theme,
  label: string,
  counts: ActivityCounts,
) {
  const parts: string[] = [];
  if (counts.running > 0) {
    parts.push(
      theme.fg("warning", `${glyphs.running} ${counts.running} running`),
    );
  }
  if (counts.done > 0) {
    parts.push(theme.fg("success", `${glyphs.done} ${counts.done} done`));
  }
  if (counts.failed > 0) {
    parts.push(theme.fg("error", `${glyphs.failed} ${counts.failed} failed`));
  }
  parts.push(theme.fg("accent", `/${label}`) + theme.fg("dim", " to view"));

  return `${theme.fg("muted", `${label}:`)} ${parts.join(theme.fg("dim", separator))}`;
}
