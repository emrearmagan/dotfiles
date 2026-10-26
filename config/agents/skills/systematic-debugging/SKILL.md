---
name: systematic-debugging
description: Find the cause of an unclear bug, failing test or build, intermittent failure, or performance regression. Use when diagnosis is requested or a previous fix failed. Handle an already understood local defect directly.
---

# Systematic Debugging

Find the cause before changing behavior. Reuse existing evidence and stop investigating once it supports a fix. Follow `AGENTS.md` for shared rules.

## 1. Reproduce the problem

1. **Read the error.** Include the stack trace and relevant code. A timeout says something took too long; it does not tell you why.
2. **Confirm the symptom.** Note the expected result, actual result, triggering input, and relevant version or settings.
3. **Run the smallest useful check.** Prefer an existing failing test, command, request, or exact manual steps. Confirm it catches the reported bug, not a setup error.
4. **Simplify when needed.** Remove extra inputs or setup one at a time while the failure remains. Keep the original case for checking the fix.
5. **Check recent changes if this is a regression.** Look at relevant code, dependency, or configuration changes.

If you cannot reproduce it:

- Inspect the available code and logs; keep explanations tentative.
- Say what evidence is missing and request only what would help distinguish the causes.
- Do not keep rebuilding an unavailable environment or claim a fix was verified there.

## 2. Trace the cause

- **Start at the failure.** Inspect the failing operation, its inputs, and the callers supplying them.
- **Follow bad values backward.** Find the assignment, conversion, or state change that first made the value wrong.
- **Check boundaries.** Across services or processes, compare what was sent, what arrived, and the settings actually in effect.
- **Compare a working case.** Look for differences in inputs, state, order, dependencies, and configuration. Read the reference sections needed to explain them.
- **Keep searches focused.** Each extra search should answer a specific unresolved question.

Example: dates appear one day early. Check storage → API response → timezone conversion. Correct the conversion that changes the date; adding a day to the display would hide the cause.

## 3. Test one explanation

1. **State the hypothesis.** What do you think causes the failure, and which observation supports it?
2. **Predict a result.** What would confirm the explanation or rule it out? If several causes fit, choose a check that separates them.
3. **Change one variable.** Use a focused test, debugger, or targeted logs. Record the result before choosing the next step.
4. **Use failed experiments.** Note what they ruled out. Remove your unsuccessful experimental edits before trying a different correction; preserve unrelated work.
5. **Reassess repeated failures.** If fixes keep failing or move the problem elsewhere, revisit the assumptions and shared behavior. Do not stack patches.

Keep temporary logs easy to find and remove. Show only the relevant output, with credentials and private data removed.

### Flaky or slow behavior

- **Intermittent failures:** record conditions, event order, shared state, and failure counts across bounded repeated runs. One pass is not enough.
- **Timing problems:** wait for the required condition with a timeout. Use controlled time when testing delays themselves; do not hide a race by increasing a sleep.
- **Performance:** measure the same workload before and after. Use a profile, timing breakdown, or query plan to locate the cost before changing code.

If the fix would go beyond the request, explain why and settle that change in scope before proceeding.

## 4. Fix and verify

For a diagnosis request, report the findings here. If the user requested a fix, continue without asking again.

1. **Choose the regression check.** Test at a boundary that exposes the real bug. Use expected results from the requirement or a known example, not a copy of the implementation's calculation.
2. **Observe the failure when practical.** A regression test must fail because of the bug, not an import error or broken fixture.
3. **Fix the cause.** Change the code responsible, check relevant callers, and preserve required validation and error handling. Leave unrelated cleanup alone.
4. **Repeat the original case.** Also run the regression test if it checks a different path. Check affected neighboring behavior and run required project checks.
5. **Expand checks when justified.** Broader changes, failures, and unresolved risks may need broader coverage. State the limits of any manual or partial check.
6. **Clean up.** Remove your temporary diagnostics and artifacts; keep useful regression tests. Rerun checks affected by cleanup or later edits, and reuse results that still apply.

Use `worker` for substantial implementation. Carry forward the diagnosis and existing results so discovery is not repeated.

## Report

- **Cause:** what went wrong, or the best current hypothesis.
- **Evidence:** reproduction, key observations, and what ruled out other explanations.
- **Fix:** what changed, if requested.
- **Checks:** commands or manual steps and their results.
- **Remaining work:** uncertainty or a concrete blocker, if any.

Stop when the requested outcome is supported by the evidence.
