// Thin Pi tool wrapper around the branch-notes script in:
//  dotfiles/config/system/scripts/branch-notes
//
// Keep note storage, git metadata, validation, and command behavior in that script.
// This extension only exposes those commands as structured tool calls.

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

const SOURCE_SCHEMA = Type.Union([Type.Literal("pi"), Type.Literal("manual")]);
const SEVERITY_SCHEMA = Type.Union([
  Type.Literal("critical"),
  Type.Literal("important"),
  Type.Literal("minor"),
]);

function runBranchNotes(
  args: string[],
  signal?: AbortSignal,
): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn("branch-notes", args, {
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

function ok(text: string, details: Record<string, unknown> = {}): ToolResult {
  return {
    content: [{ type: "text", text }],
    details: { success: true, ...details },
  };
}

function fail(text: string, details: Record<string, unknown> = {}): ToolResult {
  return {
    content: [{ type: "text", text }],
    details: { success: false, ...details },
  };
}

function parseJson(stdout: string): unknown {
  const text = stdout.trim();
  if (text === "") return null;
  return JSON.parse(text);
}

function appendOptional(args: string[], flag: string, value: unknown): void {
  if (typeof value === "string" && value.trim() !== "") {
    args.push(flag, value);
  }
}

function compactOutput(stdout: string, stderr: string): string {
  const output = stdout.trim() || stderr.trim();
  return output === "" ? "OK" : output;
}

async function executeBranchNotes(
  args: string[],
  signal: AbortSignal | undefined,
  commandName: string,
  parse: "text" | "json" = "text",
): Promise<ToolResult> {
  try {
    const result = await runBranchNotes(args, signal);
    if (result.code !== 0) {
      return fail(result.stderr || `branch-notes ${commandName} failed`, {
        command: args,
        exitCode: result.code,
      });
    }

    if (parse === "json") {
      const value = parseJson(result.stdout);
      return ok(JSON.stringify(value, null, 2), {
        command: args,
        result: value,
      });
    }

    return ok(compactOutput(result.stdout, result.stderr), {
      command: args,
      stdout: result.stdout.trim(),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return fail(`branch-notes ${commandName} failed: ${message}`, {
      command: args,
      error: message,
    });
  }
}

export default function branchNotesExtension(pi: ExtensionAPI): void {
  pi.registerTool({
    name: "branch_notes_path",
    label: "Branch Notes Path",
    description:
      "Return the branch-scoped local review notes file path for the current git worktree.",
    parameters: Type.Object({
      branch: Type.Optional(
        Type.String({
          description: "Optional branch notes bucket to inspect.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { branch?: string };
      const args = ["path"];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "path");
    },
  });

  pi.registerTool({
    name: "branch_notes_branches",
    label: "Branch Notes Branches",
    description: "List branches that currently have local review notes.",
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, signal) {
      return executeBranchNotes(
        ["branches", "--json"],
        signal,
        "branches",
        "json",
      );
    },
  });

  pi.registerTool({
    name: "branch_notes_list",
    label: "Branch Notes List",
    description:
      "List local review notes for the current branch as structured JSON.",
    parameters: Type.Object({
      branch: Type.Optional(
        Type.String({ description: "Optional branch notes bucket to list." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { branch?: string };
      const args = ["list", "--json"];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "list", "json");
    },
  });

  pi.registerTool({
    name: "branch_notes_add",
    label: "Branch Notes Add",
    description: "Add an actionable local review note to the current branch.",
    parameters: Type.Object({
      file: Type.String({
        description: "Repository-relative file path for the note.",
      }),
      line: Type.Integer({
        minimum: 1,
        description: "1-based line number for the note.",
      }),
      body: Type.String({
        description:
          "Actionable note body explaining impact and suggested fix.",
      }),
      title: Type.Optional(Type.String({ description: "Short note title." })),
      severity: Type.Optional(SEVERITY_SCHEMA),
      source: Type.Optional(SOURCE_SCHEMA),
      branch: Type.Optional(
        Type.String({
          description: "Optional branch notes bucket to write to.",
        }),
      ),
      baseRef: Type.Optional(
        Type.String({ description: "Optional base ref override." }),
      ),
      provider: Type.Optional(
        Type.String({
          description: "Optional PR provider, e.g. bitbucket or github.",
        }),
      ),
      prId: Type.Optional(
        Type.String({ description: "Optional PR id or number." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as {
        file: string;
        line: number;
        body: string;
        title?: string;
        severity?: string;
        source?: string;
        branch?: string;
        baseRef?: string;
        provider?: string;
        prId?: string;
      };

      if (!p.file || p.file.trim() === "") {
        return fail("branch_notes_add requires a file path", {
          error: "missing_file",
        });
      }
      if (!Number.isInteger(p.line) || p.line < 1) {
        return fail("branch_notes_add requires a positive integer line", {
          error: "invalid_line",
        });
      }
      if (!p.body || p.body.trim() === "") {
        return fail("branch_notes_add requires a body", {
          error: "missing_body",
        });
      }

      const args = [
        "add",
        "--file",
        p.file,
        "--line",
        String(p.line),
        "--body",
        p.body,
      ];
      appendOptional(args, "--title", p.title);
      appendOptional(args, "--severity", p.severity ?? "important");
      appendOptional(args, "--source", p.source ?? "pi");
      appendOptional(args, "--branch", p.branch);
      appendOptional(args, "--base-ref", p.baseRef);
      appendOptional(args, "--provider", p.provider);
      appendOptional(args, "--pr-id", p.prId);

      return executeBranchNotes(args, signal, "add");
    },
  });

  pi.registerTool({
    name: "branch_notes_update",
    label: "Branch Notes Update",
    description: "Update one local review note by id.",
    parameters: Type.Object({
      id: Type.String({ description: "Note id to update." }),
      file: Type.Optional(
        Type.String({ description: "Repository-relative file path for the note." }),
      ),
      line: Type.Optional(
        Type.Integer({
          minimum: 1,
          description: "1-based line number for the note.",
        }),
      ),
      body: Type.Optional(
        Type.String({
          description: "Updated note body explaining impact and suggested fix.",
        }),
      ),
      title: Type.Optional(
        Type.String({ description: "Updated short note title." }),
      ),
      severity: Type.Optional(SEVERITY_SCHEMA),
      source: Type.Optional(SOURCE_SCHEMA),
      branch: Type.Optional(
        Type.String({ description: "Optional branch notes bucket to update in." }),
      ),
      baseRef: Type.Optional(
        Type.String({ description: "Optional base ref override." }),
      ),
      provider: Type.Optional(
        Type.String({
          description: "Optional PR provider, e.g. bitbucket or github.",
        }),
      ),
      prId: Type.Optional(
        Type.String({ description: "Optional PR id or number." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as {
        id: string;
        file?: string;
        line?: number;
        body?: string;
        title?: string;
        severity?: string;
        source?: string;
        branch?: string;
        baseRef?: string;
        provider?: string;
        prId?: string;
      };

      if (!p.id || p.id.trim() === "") {
        return fail("branch_notes_update requires a note id", {
          error: "missing_id",
        });
      }
      if (p.file !== undefined && p.file.trim() === "") {
        return fail("branch_notes_update file cannot be empty", {
          error: "invalid_file",
        });
      }
      if (p.line !== undefined && (!Number.isInteger(p.line) || p.line < 1)) {
        return fail("branch_notes_update line must be a positive integer", {
          error: "invalid_line",
        });
      }
      if (p.body !== undefined && p.body.trim() === "") {
        return fail("branch_notes_update body cannot be empty", {
          error: "invalid_body",
        });
      }

      const hasUpdate = [
        p.file,
        p.line,
        p.body,
        p.title,
        p.severity,
        p.source,
        p.baseRef,
        p.provider,
        p.prId,
      ].some((value) => value !== undefined);
      if (!hasUpdate) {
        return fail("branch_notes_update requires at least one field to update", {
          error: "missing_update_field",
        });
      }

      const args = ["update", p.id];
      appendOptional(args, "--branch", p.branch);
      appendOptional(args, "--file", p.file);
      if (p.line !== undefined) args.push("--line", String(p.line));
      appendOptional(args, "--body", p.body);
      appendOptional(args, "--title", p.title);
      appendOptional(args, "--severity", p.severity);
      appendOptional(args, "--source", p.source);
      appendOptional(args, "--base-ref", p.baseRef);
      appendOptional(args, "--provider", p.provider);
      appendOptional(args, "--pr-id", p.prId);

      return executeBranchNotes(args, signal, "update");
    },
  });

  pi.registerTool({
    name: "branch_notes_delete",
    label: "Branch Notes Delete",
    description: "Delete one local review note by id.",
    parameters: Type.Object({
      id: Type.String({ description: "Note id to delete." }),
      branch: Type.Optional(
        Type.String({
          description: "Optional branch notes bucket to delete from.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { id: string; branch?: string };
      if (!p.id || p.id.trim() === "") {
        return fail("branch_notes_delete requires a note id", {
          error: "missing_id",
        });
      }

      const args = ["delete", p.id];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "delete");
    },
  });

  pi.registerTool({
    name: "branch_notes_clear",
    label: "Branch Notes Clear",
    description:
      "Clear all local review notes for a branch. Requires confirm: true.",
    parameters: Type.Object({
      branch: Type.Optional(
        Type.String({ description: "Optional branch notes bucket to clear." }),
      ),
      confirm: Type.Boolean({
        description: "Must be true to clear all notes for the branch.",
      }),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { branch?: string; confirm: boolean };
      if (p.confirm !== true) {
        return fail("branch_notes_clear cancelled: confirm must be true", {
          cancelled: true,
        });
      }

      const args = ["clear", "--yes"];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "clear");
    },
  });

  pi.registerTool({
    name: "branch_notes_delete_branch",
    label: "Branch Notes Delete Branch",
    description:
      "Delete a branch's local review notes file. Requires confirm: true.",
    parameters: Type.Object({
      branch: Type.String({ description: "Branch notes bucket to delete." }),
      confirm: Type.Boolean({
        description: "Must be true to delete the branch notes file.",
      }),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { branch: string; confirm: boolean };
      if (!p.branch || p.branch.trim() === "") {
        return fail("branch_notes_delete_branch requires a branch", {
          error: "missing_branch",
        });
      }
      if (p.confirm !== true) {
        return fail(
          "branch_notes_delete_branch cancelled: confirm must be true",
          { cancelled: true },
        );
      }

      return executeBranchNotes(
        ["delete-branch", "--branch", p.branch, "--yes"],
        signal,
        "delete-branch",
      );
    },
  });
}
