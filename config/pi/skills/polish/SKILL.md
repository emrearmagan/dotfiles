---
name: polish
description: Review recently changed files and apply simplification improvements — reduce complexity, remove dead code, improve names — without changing behavior. Use when the user runs /polish or asks to clean up / simplify recent changes.
---

# Polish

Review the recently changed files (uncommitted + recent commits on the current branch) and apply simplification improvements.

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

Only review and modify files that have been changed recently. Determine the set via:

```bash
git status --short
git diff --name-only origin/HEAD...HEAD 2>/dev/null || git diff --name-only HEAD~5..HEAD
```

Do NOT touch files outside that set.

## Process

1. List the changed files and read each one.
2. Identify concrete improvements: dead code, unclear names, redundant logic, inconsistent patterns.
3. Apply changes one file at a time.
4. After all changes, run existing tests to verify nothing is broken.
5. Summarize what you changed and why.

## Out of scope

Do NOT add new features, change public APIs, or refactor code outside the listed files.
