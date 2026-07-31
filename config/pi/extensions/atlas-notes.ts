import { spawn } from "node:child_process";
import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Expects atlas.nvim's bin/atlas-notes to be available on $PATH.
const ATLAS_NOTES_BIN = "atlas-notes";

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
    const child = spawn(ATLAS_NOTES_BIN, args, {
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
      file: Type.String({
        minLength: 1,
        description: "Repository-relative file path.",
      }),
      line: Type.Integer({
        minimum: 1,
        description: "1-based line number in the pull request head.",
      }),
      body: Type.String({
        minLength: 1,
        description: "Review note body.",
      }),
      context: Type.Optional(
        Type.String({
          description:
            "Exact source line used to detect whether the note becomes outdated. Without it, the note is always outdated.",
        }),
      ),
      type: Type.Optional(NOTE_TYPE),
    }),
    async execute(_toolCallId, params, signal) {
      const note = params as {
        target: string;
        file: string;
        line: number;
        body: string;
        context?: string;
        type?: string;
      };
      const args = [
        "add",
        "--target",
        note.target,
        "--file",
        note.file,
        "--line",
        String(note.line),
        "--body",
        note.body,
      ];
      if (note.context !== undefined) args.push("--context", note.context);
      if (note.type) args.push("--type", note.type);
      return execute(args, signal);
    },
  });
}
