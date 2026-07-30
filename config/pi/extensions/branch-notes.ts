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

const IMPORTANCE_SCHEMA = Type.Union([
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

function appendPresent(args: string[], flag: string, value: unknown): void {
  if (typeof value === "string") args.push(flag, value);
}

function singleLineError(
  command: string,
  values: Record<string, unknown>,
): ToolResult | null {
  for (const [field, value] of Object.entries(values)) {
    if (typeof value === "string" && /[\0\r\n]/u.test(value)) {
      return fail(`${command} ${field} must be a single line`, {
        error: "invalid_single_line_value",
        field,
      });
    }
  }
  return null;
}

function bodyError(
  command: string,
  body: string | undefined,
): ToolResult | null {
  if (body?.includes("\0")) {
    return fail(`${command} body cannot contain NUL`, {
      error: "invalid_body",
    });
  }
  return null;
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
      const invalid = singleLineError("branch_notes_path", {
        branch: p.branch,
      });
      if (invalid) return invalid;
      const args = ["path"];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "path");
    },
  });

  pi.registerTool({
    name: "branch_notes_branches",
    label: "Branch Notes Branches",
    description: "List branches that currently have local review notes.",
    parameters: Type.Object({
      includeArchived: Type.Optional(
        Type.Boolean({
          description: "Include branches with only archived notes.",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as { includeArchived?: boolean };
      const args = ["branches", "--json"];
      if (p.includeArchived === true) args.push("--all");
      return executeBranchNotes(args, signal, "branches", "json");
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
      includeArchived: Type.Optional(
        Type.Boolean({ description: "Include archived notes in the result." }),
      ),
      archivedOnly: Type.Optional(
        Type.Boolean({ description: "Return only archived notes." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as {
        branch?: string;
        includeArchived?: boolean;
        archivedOnly?: boolean;
      };
      const invalid = singleLineError("branch_notes_list", {
        branch: p.branch,
      });
      if (invalid) return invalid;
      const args = ["list", "--json"];
      appendOptional(args, "--branch", p.branch);
      if (p.archivedOnly === true) args.push("--archived");
      else if (p.includeArchived === true) args.push("--all");
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
      importance: Type.Optional(IMPORTANCE_SCHEMA),
      source: Type.Optional(
        Type.String({
          description:
            "Free-form source label, for example pi, atlas, or manual.",
        }),
      ),
      branch: Type.Optional(
        Type.String({
          description: "Optional branch notes bucket to write to.",
        }),
      ),
      provider: Type.Optional(
        Type.String({
          description: "Optional PR provider, e.g. bitbucket or github.",
        }),
      ),
      repoFullName: Type.Optional(
        Type.String({
          description: "Optional provider repository owner/name.",
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
        importance?: string;
        source?: string;
        branch?: string;
        provider?: string;
        repoFullName?: string;
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
      if (p.source !== undefined && p.source.trim() === "") {
        return fail("branch_notes_add source cannot be empty", {
          error: "invalid_source",
        });
      }
      const invalid =
        singleLineError("branch_notes_add", {
          file: p.file,
          title: p.title,
          source: p.source,
          branch: p.branch,
          provider: p.provider,
          repoFullName: p.repoFullName,
          prId: p.prId,
        }) ?? bodyError("branch_notes_add", p.body);
      if (invalid) return invalid;

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
      appendOptional(args, "--importance", p.importance ?? "minor");
      appendOptional(args, "--source", p.source ?? "pi");
      appendOptional(args, "--branch", p.branch);
      appendOptional(args, "--provider", p.provider);
      appendOptional(args, "--repo", p.repoFullName);
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
        Type.String({
          description: "Repository-relative file path for the note.",
        }),
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
      importance: Type.Optional(IMPORTANCE_SCHEMA),
      source: Type.Optional(
        Type.String({
          description:
            "Free-form source label, for example pi, atlas, or manual.",
        }),
      ),
      branch: Type.Optional(
        Type.String({
          description: "Optional branch notes bucket to update in.",
        }),
      ),
      provider: Type.Optional(
        Type.String({
          description: "Optional PR provider, e.g. bitbucket or github.",
        }),
      ),
      repoFullName: Type.Optional(
        Type.String({
          description: "Optional provider repository owner/name.",
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
        importance?: string;
        source?: string;
        branch?: string;
        provider?: string;
        repoFullName?: string;
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
      if (p.source !== undefined && p.source.trim() === "") {
        return fail("branch_notes_update source cannot be empty", {
          error: "invalid_source",
        });
      }
      const invalid =
        singleLineError("branch_notes_update", {
          id: p.id,
          file: p.file,
          title: p.title,
          source: p.source,
          branch: p.branch,
          provider: p.provider,
          repoFullName: p.repoFullName,
          prId: p.prId,
        }) ?? bodyError("branch_notes_update", p.body);
      if (invalid) return invalid;

      const hasUpdate = [
        p.file,
        p.line,
        p.body,
        p.title,
        p.importance,
        p.source,
        p.provider,
        p.repoFullName,
        p.prId,
      ].some((value) => value !== undefined);
      if (!hasUpdate) {
        return fail(
          "branch_notes_update requires at least one field to update",
          {
            error: "missing_update_field",
          },
        );
      }

      const args = ["update", p.id];
      appendOptional(args, "--branch", p.branch);
      appendPresent(args, "--file", p.file);
      if (p.line !== undefined) args.push("--line", String(p.line));
      appendPresent(args, "--body", p.body);
      appendPresent(args, "--title", p.title);
      appendOptional(args, "--importance", p.importance);
      appendPresent(args, "--source", p.source);
      appendPresent(args, "--provider", p.provider);
      appendPresent(args, "--repo", p.repoFullName);
      appendPresent(args, "--pr-id", p.prId);

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
      const invalid = singleLineError("branch_notes_delete", {
        id: p.id,
        branch: p.branch,
      });
      if (invalid) return invalid;

      const args = ["delete", p.id];
      appendOptional(args, "--branch", p.branch);
      return executeBranchNotes(args, signal, "delete");
    },
  });

  pi.registerTool({
    name: "branch_notes_archive",
    label: "Branch Notes Archive",
    description:
      "Archive or unarchive one note, or every note in a branch when id is omitted.",
    parameters: Type.Object({
      id: Type.Optional(Type.String({ description: "Optional note id." })),
      branch: Type.Optional(
        Type.String({ description: "Optional branch notes bucket." }),
      ),
      archived: Type.Optional(
        Type.Boolean({ description: "False unarchives; defaults to true." }),
      ),
      reason: Type.Optional(
        Type.String({ description: "Optional archive reason." }),
      ),
    }),
    async execute(_toolCallId, params, signal) {
      const p = params as {
        id?: string;
        branch?: string;
        archived?: boolean;
        reason?: string;
      };
      const args = ["archive"];
      if (p.id !== undefined) {
        if (p.id.trim() === "") {
          return fail("branch_notes_archive id cannot be empty", {
            error: "invalid_id",
          });
        }
        args.push(p.id);
      }
      const invalid = singleLineError("branch_notes_archive", {
        id: p.id,
        branch: p.branch,
        reason: p.reason,
      });
      if (invalid) return invalid;
      appendOptional(args, "--branch", p.branch);
      appendOptional(args, "--reason", p.reason);
      if (p.archived === false) args.push("--unarchive");
      return executeBranchNotes(args, signal, "archive");
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
      const invalid = singleLineError("branch_notes_clear", {
        branch: p.branch,
      });
      if (invalid) return invalid;
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
      const invalid = singleLineError("branch_notes_delete_branch", {
        branch: p.branch,
      });
      if (invalid) return invalid;
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
