---
name: worker
description: 'Implement code from a spec or requirement — plan, small steps, evidence-verified. Triggers: "build", "implement", "fix", "work on", "let''s start", or any multi-step change after a spec.'
---

# Worker

Implement requested changes with a tight loop: **plan → implement → verify → report**.

## Principles

- **Read before edit.** Understand existing code before changing it.
- **Targeted edits, not rewrites.** Smallest change that achieves the goal.
- **Diagnose, don't guess.** If something fails, investigate (see `/skill:systematic-debugging`).
- **Do not commit unless asked.** Only commit when the user explicitly asks.
- **Report what changed.** End with a clear summary of files modified and verification done.

## 1. Plan

For multi-step work, create `pi-tasks` entries before editing. Skip formal task planning for one small, obvious change.

Each task should include:

- exact file path(s)
- intended change
- verification command or concrete manual check

Keep tasks small and update them as reality changes.

## 2. Implement

Work one task at a time.

- Make the smallest change that satisfies the task.
- Do not bundle unrelated cleanup.
- If the plan becomes wrong, update the task before continuing.

## 3. Verify

Use the tightest useful feedback loop:

- focused test/check for the changed code
- one command that reproduces the bug or validates the feature
- manual check only when automation is not practical

Run the relevant check before claiming success. Broader checks are for broad or risky changes.

If a check fails, do not stack guesses. Diagnose the failure first.

Iron law: if you have not run the verification command in this message, do not claim it passes.

For the full claim→evidence table, see `references/verification.md`.

## 4. Report

End with:

```markdown
## Changes Made
- `path/to/file` — what changed and why

## Verification
- Ran `<command>` — result
```

No "should work". Only evidence-backed claims.
