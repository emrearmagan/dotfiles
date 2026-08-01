---
name: worker
description: 'Implement code from a spec or requirement — plan, small steps, and follow-up friendly. Triggers: "build", "implement", "fix", "work on", "let''s start", or any multi-step change after a spec.'
---

# Worker

Implement requested changes with a tight loop: **plan → implement → collect follow-ups → report**.

## Principles

- **Read before edit.** Understand existing code before changing it.
- **Lazy senior ladder.** Before adding code, stop at first rung that holds: need it at all, already exists here, stdlib/native/installed dep, one-liner, then minimum code.
- **Targeted edits, not rewrites.** Smallest change that achieves the goal.
- **Diagnose, don't guess.** If something fails, investigate (see `/skill:systematic-debugging`).
- **Do not commit unless asked.** Only commit when the user explicitly asks.
- **Report what changed.** End with a concise summary of modified files and behavior.

## 1. Plan

For multi-step work, create `pi-tasks` entries before editing. Skip formal task planning for one small, obvious change.

Each task should include:

- exact file path(s)
- intended change

Keep tasks small and update them as reality changes.

## 2. Implement

Work one task at a time.

- Make the smallest change that satisfies the task.
- For bug fixes, grep callers before touching shared functions; fix root cause once, not symptoms per caller.
- Mark deliberate shortcuts only when useful; the comment must name the ceiling and upgrade trigger.
- Do not bundle unrelated cleanup.
- If the plan becomes wrong, update the task before continuing.

## 3. Verification

For iterative work, defer verification through follow-up changes. Do not create a task solely to track it, and do not repeatedly ask whether to verify.

When code or executable configuration behavior changed and a meaningful check was deferred, append this line to implementation summaries:

> Verification: pending — say “verify” when ready.

Omit verification status for documentation, prose, comments, formatting-only edits, and changes where no useful check exists or the edit itself fully establishes the requested outcome. Do not print a replacement such as `No verification needed`.

Treat requests to verify, test, do a final pass, commit, or create a PR as verification requests. If the user otherwise signals that behavior-changing work is done, ask once whether to verify. After verification, remove the reminder until another behavioral change is made.

Diagnostic commands needed to investigate a failure are allowed, but do not run broader checks automatically.

## 4. Report

End with a concise summary of the files changed and behavior implemented. Add the verification reminder only when the criteria above apply.
