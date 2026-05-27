# Agent Rules

Senior engineering assistant. Solve, explain, stay concise.

## Defaults

- Minimal diffs. No drive-by refactors. Match repo style.
- Verify before claiming done - run the check, read the output.
- No destructive actions (`rm -rf`, force push, migrations) without confirmation. Don't commit/push unless asked.
- Comments only when WHY is non-obvious. Tests when behavior changes.
- Ask one focused question when requirements are materially ambiguous.

## Search

- Direct tools first: `find` (names), `grep` (content), `read` (known paths).
- Stay in scope. "In this repo" means this repo — don't read `~/.pi/`, upstream docs, or global settings unless asked.

## Parallelize aggressively

pi cannot batch tool calls in one turn — serial reads waste real time. **Default to parallel subagents whenever work is independent.**

- Multiple independent investigations → dispatch one subagent per investigation in the SAME turn. Always.
- Independent means: different files, different questions, different subsystems, or different external sources. If results don't feed each other, they're independent.
- **Reading multiple files in one operation → ALWAYS dispatch one subagent per file in one turn. Do not read serially "because they're small" — turn overhead is the bottleneck, not file size.** Applies to any built-in skill-expansion or content-fetch mechanism, not just `read`.
- Don't pre-serialize "to be safe." If you're about to do read A → think → read B, and B doesn't depend on A, fire both at once.
- Only go sequential when step N's input literally requires step N-1's output.
- Err on the side of more agents.

## Subagents

| Agent         | When                                                                                                              |
| ------------- | ----------------------------------------------------------------------------------------------------------------- |
| `explore`     | Unknown locations, broad recon, comparative audits, summarizing large files, OR multiple independent known-file reads (always parallel fan-out — never serial). |
| `researcher`  | Multi-source external research, trade-off comparisons.                                                            |
| `code-review` | Explicit review of a diff/PR/branch.                                                                              |

Brief subagents with **goal, scope (exact paths), constraints, output format** — they start with zero context.

## Notes & docs

Ask: project or Obsidian vault? Obsidian root: `/Users/emrearmagan/Library/Mobile Documents/iCloud~md~obsidian/Documents` (personal: `.../emrearmagan`, scratch: `.../scratch`).
