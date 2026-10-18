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
        description: "Pull request head commit SHA the line numbers refer to.",
      }),
      file: Type.String({
        minLength: 1,
        description: "Repository-relative file path.",
      }),
      start_line: Type.Integer({
        minimum: 1,
        description: "First line of the note, 1-based, in that commit.",
      }),
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
            "Source lines of the note, separated by newlines. Shown with the note in Atlas.",
        }),
      ),
      type: Type.Optional(NOTE_TYPE),
    }),
    async execute(_toolCallId, params, signal) {
      const note = params as {
        target: string;
        commit: string;
        file: string;
        start_line: number;
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
        "--start-line",
        String(note.start_line),
        "--body",
        note.body,
      ];
      if (note.end_line !== undefined)
        args.push("--end-line", String(note.end_line));
      if (note.context !== undefined) args.push("--context", note.context);
      if (note.type) args.push("--type", note.type);
      return execute(args, signal);
    },
  });
}
