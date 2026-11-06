/**
 * Atlas Notes Extension
 *
 * Provides tools that let the LLM list, add, update and delete private Atlas
 * review notes on pull request diffs through the `atlas-notes` CLI. A note can
 * be an issue, suggestion, note or praise and is shown on its file, or next to
 * its lines, in Atlas.
 *
 * Usage:
 *   Ask the LLM: "review this PR and leave Atlas notes on anything risky"
 *
 * Requires:
 *   atlas-notes on PATH
 */

import { spawn } from "node:child_process";
import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ToolResult = {
  content: Array<{ type: "text"; text: string }>;
  details: Record<string, unknown>;
};

type RunResult = {
  code: number | null;
  stdout: string;
  stderr: string;
};

const NOTE_TYPE = Type.Union([
  Type.Literal("issue"),
  Type.Literal("suggestion"),
  Type.Literal("note"),
  Type.Literal("praise"),
]);

function runAtlasNotes(
  args: string[],
  signal?: AbortSignal,
): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn("atlas-notes", args, {
      cwd: process.cwd(),
      env: process.env,
      signal,
    });
    let stdout = "";
    let stderr = "";

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      stdout += chunk;
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk;
    });
    child.on("error", reject);
    child.on("close", (code) => resolve({ code, stdout, stderr }));
  });
}

function output(
  success: boolean,
  text: string,
  details: Record<string, unknown>,
): ToolResult {
  return {
    content: [{ type: "text", text }],
    details: { success, ...details },
  };
}

async function execute(
  args: string[],
  signal?: AbortSignal,
): Promise<ToolResult> {
  try {
    const result = await runAtlasNotes(args, signal);
    if (result.code !== 0) {
      return output(false, result.stderr.trim() || "atlas-notes failed", {
        command: args,
        exitCode: result.code,
      });
    }

    const value = JSON.parse(result.stdout);
    return output(true, JSON.stringify(value, null, 2), {
      command: args,
      result: value,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return output(false, message, { command: args, error: message });
  }
}

export default function atlasNotesExtension(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "atlas_notes_list",
    label: "Atlas Notes List",
    description:
      "List local Atlas review notes, optionally limited to one pull request.",
    parameters: Type.Object({
      target: Type.Optional(
        Type.String({
          minLength: 1,
          description: "Pull request URL or canonical Atlas target.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const { target } = params as { target?: string };
      const args = ["list"];
      if (target) args.push("--target", target);
      return execute(args, signal);
    },
  });

  pi.registerTool({
    name: "atlas_notes_add",
    label: "Atlas Notes Add",
    description: "Add a private Atlas note to a pull request diff.",
    parameters: Type.Object({
      target: Type.String({
        minLength: 1,
        description: "Pull request URL or canonical Atlas target.",
      }),
      commit: Type.String({
        minLength: 1,
        description: "Pull request head commit SHA the note refers to.",
      }),
      file: Type.String({
        minLength: 1,
        description: "Repository-relative file path.",
      }),
      start_line: Type.Optional(
        Type.Integer({
          minimum: 1,
          description:
            "First line of the note, 1-based, in that commit. Omit for a file note.",
        }),
      ),
      end_line: Type.Optional(
        Type.Integer({
          minimum: 1,
          description:
            "Last line of a multi-line note. Defaults to start_line.",
        }),
      ),
      body: Type.String({
        minLength: 1,
        description: "Review note body.",
      }),
      context: Type.Optional(
        Type.String({
          description:
            "Source lines of the note, separated by newlines. Shown with the note in Atlas. Needs start_line.",
        }),
      ),
      type: Type.Optional(NOTE_TYPE),
    }),
    async execute(_toolCallId, params, signal) {
      const note = params as {
        target: string;
        commit: string;
        file: string;
        start_line?: number;
        end_line?: number;
        body: string;
        context?: string;
        type?: string;
      };
      const args = [
        "add",
        "--target",
        note.target,
        "--commit",
        note.commit,
        "--file",
        note.file,
        "--body",
        note.body,
      ];
      if (note.start_line !== undefined)
        args.push("--start-line", String(note.start_line));
      if (note.end_line !== undefined)
        args.push("--end-line", String(note.end_line));
      if (note.context !== undefined) args.push("--context", note.context);
      if (note.type) args.push("--type", note.type);
      return execute(args, signal);
    },
  });

  pi.registerTool({
    name: "atlas_notes_update",
    label: "Atlas Notes Update",
    description:
      "Change the body, type, or resolved state of an Atlas note. Its file and lines cannot change.",
    parameters: Type.Object({
      target: Type.String({
        minLength: 1,
        description: "Pull request URL or canonical Atlas target.",
      }),
      id: Type.String({
        minLength: 1,
        description: "Note id from atlas_notes_list.",
      }),
      body: Type.Optional(
        Type.String({ minLength: 1, description: "New note body." }),
      ),
      type: Type.Optional(NOTE_TYPE),
      resolved: Type.Optional(
        Type.Boolean({ description: "Mark the note resolved or open." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const note = params as {
        target: string;
        id: string;
        body?: string;
        type?: string;
        resolved?: boolean;
      };
      const args = ["update", "--target", note.target, "--id", note.id];
      if (note.body !== undefined) args.push("--body", note.body);
      if (note.type) args.push("--type", note.type);
      if (note.resolved !== undefined)
        args.push("--resolved", String(note.resolved));
      return execute(args, signal);
    },
  });

  pi.registerTool({
    name: "atlas_notes_delete",
    label: "Atlas Notes Delete",
    description: "Delete an Atlas note.",
    parameters: Type.Object({
      target: Type.String({
        minLength: 1,
        description: "Pull request URL or canonical Atlas target.",
      }),
      id: Type.String({
        minLength: 1,
        description: "Note id from atlas_notes_list.",
      }),
    }),
    async execute(_toolCallId, params, signal) {
      const { target, id } = params as { target: string; id: string };
      return execute(["delete", "--target", target, "--id", id], signal);
    },
  });
}
