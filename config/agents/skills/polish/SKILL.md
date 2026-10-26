---
name: polish
description: 'Simplify the requested code or current work — remove dead code, clearer names, less nesting — without behavior change. Triggers: "/polish", "clean up", "simplify", "tidy".'
---

# Polish

Apply useful simplifications within the requested scope or the current work established in the conversation.

## Principles

- **Preserve functionality**: Never change what the code does. All existing tests must continue to pass.
- **Apply project standards**: Follow any conventions from `CLAUDE.md` or `AGENTS.md` in this project.
- **Enhance clarity**: Reduce unnecessary complexity and nesting, eliminate redundant code and abstractions, improve variable and function names, consolidate related logic. Avoid nested ternary operators: prefer switch statements or if/else chains for multiple conditions.
- **Maintain balance**: Do not over-simplify. Avoid overly clever solutions that are hard to understand. Do not combine too many concerns into single functions. Do not remove helpful abstractions. Prioritize readability over fewer lines.

## Comments

Remove **only** boilerplate comments that restate what the code already says — e.g. `// constructor`, `// getter`, `// loop through items`, `// return result`.

**Always keep:**

- `TODO`, `FIXME`, `HACK`, `XXX`, `NOTE` markers — regardless of phrasing.
- Comments explaining _why_ something is done a particular way, or referencing an external constraint, bug, or workaround.
- Comments documenting non-obvious invariants, edge cases, or gotchas.
- Comments containing URLs, ticket references (`JIRA-123`), or links to docs / specs.
- Doc comments (`/** … */`, `///`, `"""…"""`) on exported / public APIs.
- License headers and `@ts-expect-error` / `@ts-ignore` lines with explanations.

When in doubt: keep the comment. Removing a comment is only safe when its text is fully redundant with the code immediately below it.

## Scope

Use the user's explicit scope or the current work established in the conversation. Ask only when the scope is materially ambiguous. Do not automatically include recent commits or unrelated changes.

Supported scopes:

- **Current uncommitted changes** — files from `git status --short` / working tree diffs.
- **Current branch** — files changed on the current branch versus its upstream/base.
- **Last N commits** — files changed in a user-specified number of recent commits.

Do NOT touch files outside the selected scope.

## Process

1. **Inspect the scope.** Read the relevant files or diff directly. Stop exploring when the intended simplifications and behavior are clear.
2. **Apply related edits together.** Keep only changes that improve clarity without changing behavior or public APIs.
3. **Verify affected code.** Run the smallest useful checks after the batch. Broaden checks only when the scope, risk, or a failure warrants it.
4. **Summarize** meaningful changes and verification results.

## Out of scope

Do NOT add new features, change public APIs, or refactor code outside the listed files.
