---
name: feature-work
description: End-to-end discipline for working on a feature — plan first, implement in small steps, verify with evidence before claiming done. Use when starting a new feature, implementing a spec, or tackling a multi-step change. Triggers on phrases like "build", "implement", "add feature", "work on", "let's start", or when given a spec/requirements.
---

# Feature Work

Three phases. Each one has a gate. Don't move forward without passing the gate.

```
PLAN  →  IMPLEMENT  →  VERIFY
 │           │            │
 gate:      gate:        gate:
 written    test passes  evidence run in this turn
 plan       per step     before any "done" claim
```

## Phase 1: Plan Before Code

**Gate:** A written plan exists before touching any file.

For anything beyond a one-line change, write a plan first. Save to `docs/plans/YYYY-MM-DD-<feature>.md` (or alongside the spec).

Plan structure:

```markdown
# <Feature> Plan

**Goal:** one sentence.
**Approach:** 2-3 sentences on architecture.

## Files
- Create: path/to/new.ts
- Modify: path/to/existing.ts (lines X-Y, reason)
- Test: path/to/test.ts

## Tasks
### 1. <small focused task>
- [ ] Step: <action, exact code or command>
  Verify: <command + expected output>
- [ ] Step: ...
  Verify: ...

### 2. <next task>
...
```

Rules for the plan:
- **Bite-sized steps**, 2-5 minutes each. "Add the function" is one step. "Add error handling" is not — be specific.
- **No placeholders.** No "TBD", "add validation here", "similar to task N". If a step changes code, show the code. If it runs a command, show the exact command and expected output.
- **Exact file paths.** Always.
- **One responsibility per file.** Don't bundle unrelated changes.
- **Frequent commits.** Each task ends with a commit step.

Self-review the plan before starting:
1. Does every spec requirement map to a task?
2. Are there any placeholder phrases? Fix them.
3. Do types/function names match across tasks?

## Phase 2: Implement One Step at a Time

**Gate:** Each step's verify command passes before the next step starts.

- Implement the step exactly as planned.
- Run the verify command. Confirm it does what the plan says.
- If it fails, do not stack a second fix. Revert, understand why, fix once.
- No "while I'm here" cleanup or refactoring outside the plan.
- Commit at the boundaries the plan specifies.

If the plan is wrong, update the plan, then continue. Don't drift silently.

## Phase 3: Verify Before Claiming Done

**Iron Law:**

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command **in this message**, you cannot claim it passes.

### The Gate

Before saying *any* of "done", "fixed", "passing", "ready", "great", "perfect", "should work":

1. **Identify:** what command proves this claim?
2. **Run:** execute the full command fresh.
3. **Read:** exit code + full output, count failures.
4. **Verify:** does the output actually confirm the claim?
5. **Then** make the claim, citing the evidence.

Skip any step = lying, not verifying.

### Claim → Evidence Required

| Claim | Required evidence | Not enough |
|---|---|---|
| Tests pass | Test command output: 0 failures | "Should pass", earlier run |
| Build succeeds | Build command exit 0 | Linter passed |
| Bug fixed | Original repro now passes | Code changed, "looks right" |
| Linter clean | Linter output: 0 errors | Partial check |
| Requirements met | Line-by-line checklist vs plan | Tests pass |
| Subagent finished | `git diff` shows expected changes | Agent reports success |

### Red Flags — STOP

If you catch yourself doing any of these, you are about to claim without evidence:

- Using "should", "probably", "seems to", "looks like".
- "Great!", "Perfect!", "Done!" before running anything.
- About to commit/PR without running tests.
- Trusting a subagent's "success" report without inspecting the diff.
- Partial verification ("linter passed so build works").
- "Just this once" / "I'm tired" / "I'm confident".

### Rationalizations

| Excuse | Reality |
|---|---|
| "Should work now" | Run the verification. |
| "I'm confident" | Confidence ≠ evidence. |
| "Just this once" | No exceptions. |
| "Linter passed" | Linter ≠ compiler ≠ tests. |
| "Agent said success" | Verify the diff independently. |
| "Partial check is enough" | Partial proves nothing. |

## Bottom Line

Plan written → implement step-by-step with per-step verification → run the proof command fresh before claiming anything is done. Three gates, no shortcuts.
