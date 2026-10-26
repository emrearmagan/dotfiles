/**
 * Tool Display Extension
 *
 * Draws read, write, edit, grep, find, ls, bash, codemode, clipboard and Atlas note
 * calls as one short line with a small summary of the result. Ctrl+O expands a call
 * to pi's full display, including the diff of an edit.
 *
 * Usage:
 *   Runs automatically. Ctrl+O toggles the full output.
 */

import type {
  AgentToolResult,
  ExtensionAPI,
  Theme,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

type Args = Record<string, any>;

type ToolStyle = {
  describe: (args: Args) => string;
  body: (output: string, theme: Theme, result: AgentToolResult<any>, args: Args) => string;
};

type CodemodeCall = { name: string; args?: string; status: string };

const MAX_DESCRIPTION = 100;
const MAX_PREVIEW_LINE = 120;

const SINGULAR: Record<string, string> = { lines: "line", edits: "edit" };

const CALL_ICONS: Record<string, [string, string]> = {
  ok: ["success", "✓"],
  error: ["error", "✗"],
  running: ["warning", "…"],
  cancelled: ["muted", "⊘"],
};

function oneLine(text: string): string {
  const line = text.replace(/\s+/g, " ").trim();
  return line.length > MAX_DESCRIPTION
    ? `${line.slice(0, MAX_DESCRIPTION - 1)}…`
    : line;
}

function plural(n: number, noun: string): string {
  return `${n} ${n === 1 ? (SINGULAR[noun] ?? noun) : noun}`;
}

function textOf(content: AgentToolResult<unknown>["content"]): string {
  return content
    .map((part) => (part.type === "text" ? part.text : ""))
    .join("\n")
    .trim();
}

function summary(text: string, theme: Theme): string {
  return theme.fg("muted", `↳ ${text} • ctrl+o to expand`);
}

function lineCount(output: string, theme: Theme): string {
  const lines = output ? output.split("\n").length : 0;
  return lines ? summary(plural(lines, "lines"), theme) : theme.fg("muted", "↳ no output");
}

function preview(output: string, lines: number, theme: Theme): string {
  const all = output.split("\n");
  // One long line, like a JSON result, would otherwise wrap over the whole screen
  const shown = all
    .slice(0, lines)
    .map((line) => (line.length > MAX_PREVIEW_LINE ? `${line.slice(0, MAX_PREVIEW_LINE - 1)}…` : line))
    .map((line) => theme.fg("toolOutput", line));
  if (all.length > lines) {
    shown.push(theme.fg("muted", `… ${plural(all.length - lines, "lines")} more (ctrl+o)`));
  }
  return shown.join("\n");
}

// Added and removed lines of a unified diff, skipping the file headers before the first hunk
function patchStats(patch: string): [number, number] {
  let added = 0;
  let removed = 0;
  let inHunk = false;
  for (const line of patch.split("\n")) {
    if (line.startsWith("@@")) inHunk = true;
    else if (inHunk && line.startsWith("+")) added++;
    else if (inHunk && line.startsWith("-")) removed++;
  }
  return [added, removed];
}

// Describe a call the same way as a direct tool call, e.g. "read config/agents/AGENTS.md"
function callArgs(call: CodemodeCall): string {
  try {
    const args = JSON.parse(call.args ?? "");
    return STYLES[call.name]?.describe(args) ?? Object.values(args).join(" ");
  } catch {
    return call.args ?? "";
  }
}

function codemodeCalls(calls: CodemodeCall[], theme: Theme): string[] {
  return calls.map((call) => {
    const [color, icon] = CALL_ICONS[call.status] ?? ["muted", "•"];
    return `${theme.fg(color as any, icon)} ${theme.fg("toolTitle", call.name)} ${theme.fg("muted", oneLine(callArgs(call)))}`;
  });
}

const STYLES: Record<string, ToolStyle> = {
  read: {
    describe: (args) =>
      args.offset
        ? `${args.path}:${args.offset}${args.limit ? `-${args.offset + args.limit - 1}` : ""}`
        : args.path,
    body: (output, theme) => lineCount(output, theme),
  },
  write: {
    describe: (args) => args.path,
    body: (_output, theme, _result, args) => lineCount(String(args.content ?? ""), theme),
  },
  edit: {
    describe: (args) => args.path,
    body: (_output, theme, result, args) => {
      if (typeof result.details?.patch !== "string") {
        return summary(plural(Array.isArray(args.edits) ? args.edits.length : 1, "edits"), theme);
      }
      const [added, removed] = patchStats(result.details.patch);
      return `${theme.fg("muted", "↳")} ${theme.fg("success", `+${added}`)} ${theme.fg("error", `−${removed}`)} ${theme.fg("muted", "• ctrl+o to expand")}`;
    },
  },
  grep: {
    describe: (args) => `${args.pattern} ${args.path ?? "."}`,
    body: (output, theme) => lineCount(output, theme),
  },
  find: {
    describe: (args) => `${args.pattern} ${args.path ?? "."}`,
    body: (output, theme) => lineCount(output, theme),
  },
  ls: {
    describe: (args) => args.path ?? ".",
    body: (output, theme) => lineCount(output, theme),
  },
  bash: {
    describe: (args) => args.command,
    body: (output, theme) => preview(output, 5, theme),
  },
  copy_to_clipboard: {
    describe: (args) => args.text ?? "",
    body: (_output, theme, _result, args) => lineCount(String(args.text ?? ""), theme),
  },
  atlas_notes_list: {
    describe: (args) => args.target ?? "",
    body: (output, theme) => lineCount(output, theme),
  },
  atlas_notes_add: {
    describe: (args) =>
      `${args.file}:${args.start_line}${args.end_line ? `-${args.end_line}` : ""}`,
    body: (output, theme) => lineCount(output, theme),
  },
  codemode: {
    describe: () => "",
    body: (_output, theme, result) => {
      const calls = codemodeCalls(result.details?.calls ?? [], theme);
      if (calls.length > 0) return calls.join("\n");
      // The first content item is the script's status header, the rest is its output
      const content = result.content.length > 1 ? result.content.slice(1) : result.content;
      return preview(textOf(content), 2, theme);
    },
  },
};

export default function (pi: ExtensionAPI) {
  pi.registerToolRenderer((toolName, next) => {
    const style = STYLES[toolName];
    if (!style) return next();
    const original = next();

    return {
      renderCall(args, theme, context) {
        // pi's renderers expect their own component, not ours
        if (context.expanded && original?.renderCall) {
          return original.renderCall(args, theme, { ...context, lastComponent: undefined });
        }
        const title = theme.fg("toolTitle", theme.bold(toolName));
        const description = oneLine(style.describe(args ?? {}));
        return new Text(description ? `${title} ${theme.fg("accent", description)}` : title, 0, 0);
      },
      renderResult(result, options, theme, context) {
        if (options.expanded && original?.renderResult) {
          return original.renderResult(result, options, theme, { ...context, lastComponent: undefined });
        }
        // Show codemode's calls while its script still runs
        if (options.isPartial) {
          const calls = toolName === "codemode" ? codemodeCalls(result.details?.calls ?? [], theme) : [];
          return new Text(calls.join("\n"), 0, 0);
        }
        const output = textOf(result.content);
        if (context.isError) {
          return new Text(theme.fg("error", output.split("\n").slice(0, 4).join("\n")), 0, 0);
        }
        return new Text(style.body(output, theme, result, context.args ?? {}), 0, 0);
      },
    };
  });
}
