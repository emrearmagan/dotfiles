---
name: worker
description: End-to-end discipline for implementing code changes — plan first, implement in small targeted steps, verify with evidence before claiming done. Use when starting a feature, fixing a bug, implementing a spec, or any multi-step code change. Triggers on phrases like "build", "implement", "add feature", "fix", "work on", "let's start", or when given a spec/requirements.
---

# Worker

You work autonomously to complete the assigned task. Three phases, each with a gate. Don't move forward without passing the gate.

```
PLAN  →  IMPLEMENT  →  VERIFY
```

## Principles

- **Read before edit.** Understand existing code before changing it.
- **Targeted edits, not rewrites.** Smallest change that achieves the goal.
- **Diagnose, don't guess.** If something fails, investigate (see `/skill:systematic-debugging`).
- **Report what changed.** End with a clear summary of files modified and verification done.

## Phase 1: Plan Before Code

**Gate:** A plan exists in the `pi-tasks` tool before touching any file.

For anything beyond a one-line change, build the plan as `pi-tasks` entries — not as inline markdown. Tasks are queryable, persist across the session, and the model can mark them as it progresses.

Workflow:

1. Define the goal (one sentence) and approach (2–3 sentences) in your first response.
2. Use `pi-tasks` to add each task. Each task has:
   - A short description (e.g. "Add `validateEmail` to `auth/utils.ts`").
   - A verify command + expected output.
3. Self-review the task list before starting:
   - Does every spec requirement map to a task?
   - Any placeholder phrases ("TBD", "add validation here")? Fix them.
   - Do types / function names match across tasks?

Rules for tasks:

- **Bite-sized**, 2–5 minutes each. "Add the function" is one task. "Add error handling" is not — be specific.
- **No placeholders.** If a task touches code, you must know exactly what change. If it runs a command, you must know the exact command and expected output.
- **Exact file paths.** Always.
- **One responsibility per file.** Don't bundle unrelated changes.
- **Frequent commits.** End tasks at sensible commit boundaries.

## Phase 2: Implement One Task at a Time

**Gate:** Each task's verify command passes before the next task starts.

- Implement the task exactly as planned.
- Run the verify command. Confirm output.
- If it fails, do not stack a second fix. Revert, understand why, fix once.
- No "while I'm here" cleanup or refactoring outside the plan.
- Mark the task done in `pi-tasks` before moving on.

If the plan is wrong, update the task list, then continue. Don't drift silently.

## Phase 3: Verify Before Claiming Done

**Iron Law:** if you haven't run the verification command **in this message**, you cannot claim it passes.

See AGENTS.md's Validation section for the always-on rule. For the full claim→evidence table, red flags, and rationalization catchers, read `references/verification.md`.

## Final Report

When done, end with this structure:

```markdown
## Changes Made

- `path/to/file.ts` — what changed and why
- `path/to/other.ts` — what changed and why

## Verification

- Ran `npm test` — 34/34 passing.
- Ran `npm run build` — exit 0.
- Reproduced original bug, now fixed.
```

No "should work" or "looks right" — only evidence-backed claims.
