---
name: worker
description: Implement substantial code changes from requirements, a spec, or an agreed plan. Work in small steps and check each change. Handle small, obvious edits directly.
---

# Worker

Take the request through implementation, checks, and a short report. Follow `AGENTS.md` for shared rules on scope, permissions, and delegation.

## 1. Plan

- Identify what should work when you're done, including stated limits and compatibility needs.
- Start from the existing spec or plan. Keep decisions that are already settled.
- Ask one focused question only if the answer would change what you build or whether you can proceed safely. Continue independent work while waiting.
- Check the working tree so you can distinguish existing edits from your own.
- Read the code you expect to change, its callers, and nearby tests before editing. Check callers before changing a shared interface.
- Search likely paths first. Widen the search only to answer something still unclear.
- Prefer existing helpers, native features, and simple local changes. Add a dependency or abstraction only when simpler options fall short.
- Write a few steps for substantial work. Include paths, expected results, and checks where useful; skip a written plan for a straightforward edit.
- Use `todo` when asked or when tracking a few milestones will help you finish the work.
- Delegate only when useful under `AGENTS.md`. Give each agent a clear question or set of files, enough context, and the result you need back.

## 2. Implement

Repeat this loop for each small, complete change:

1. Choose the check for the change. Add or update tests for what users or callers depend on, including important failure cases. For a bug fix, reproduce the failure first when practical and check that the test fails because of the bug.
2. Make the edit using the surrounding code's conventions. Keep required validation, error handling, security, and accessibility intact. Leave unrelated cleanup alone.
3. Run a focused check and read its output before starting changes that depend on this one. Confirm a regression test passes with the fix.
4. If the cause is unclear or a check fails unexpectedly, use `systematic-debugging` before trying another fix. Separate code defects from broken test setup, missing dependencies, and environment problems.
5. Update the remaining steps when new findings change the approach. Continue until the pieces needed for the request are in place.

- Use public interfaces where practical. Don't test private call sequences or copy the implementation into the test.
- For docs, configuration, and other low-impact edits, use a suitable direct check. Don't add a test just to have one.
- Review delegated changes and their supporting checks before using them. Follow up on gaps or disagreements without repeating all the work.

## 3. Verify

- Check the finished behavior against the whole request, including later corrections.
- Check affected callers and connections between components where a local test isn't enough.
- Use [references/verification.md](references/verification.md) to choose checks or handle incomplete results.
- Reuse passing results while the code and setup they depend on haven't changed.
- Rerun affected checks after edits. Broaden them when failures or unanswered questions call for it.
- Read your diff for mistakes, accidental edits, unnecessary complexity, and missed requirements.
- Fix remaining issues within the task and rerun the checks those fixes affect.

## 4. Report

- Finish the whole request, including its checks. Stop only when it's done or a specific blocker prevents further progress.
- For a blocker, say what's left, why you can't continue, and what would let you proceed.
- Briefly report the result, important changed files, checks run, and anything still unverified.
- Don't commit or push unless asked.
