---
name: systematic-debugging
description: 'Root-cause a bug before fixing — reproduce, evidence, single hypothesis, minimal test. Use for any bug, test failure, build break, or unexpected behavior — especially when a "quick fix" feels obvious.'
---

# Systematic Debugging

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Random fixes waste time and create new bugs. Symptom fixes are failure. If you haven't completed Phase 1, you cannot propose fixes.

## When to Use

Any technical issue: test failures, production bugs, unexpected behavior, performance problems, build failures, integration issues.

**Especially when:**

- Under time pressure (emergencies make guessing tempting — systematic is faster than thrashing).
- "Just one quick fix" seems obvious.
- A previous fix didn't work, or you've already tried multiple.
- You don't fully understand the issue.

## Phase 1: Root Cause Investigation

1. **Read errors carefully.** Don't skip stack traces. Line numbers, file paths, error codes often contain the exact answer.
2. **Reproduce consistently.** Build the tightest red/green feedback loop you can: focused test, one command, small script, or exact manual steps. If not reproducible → gather more data, don't guess.
3. **Check recent changes.** Git diff, deploys, dep updates, config changes.
4. **In multi-component systems, instrument every boundary** _before_ proposing fixes:
   - Log what data enters each component, what exits.
   - Verify env/config propagation across layers.
   - Run once to see _where_ it breaks, then investigate that layer.
5. **Trace data backward.** When the error is deep in the stack: where does the bad value originate? What called this with it? Keep tracing up. Fix at the source, not the symptom.
6. **Minimize the repro** before hypothesizing. Remove inputs, steps, config, and callers until only load-bearing pieces remain.

## Phase 2: Pattern Analysis

- **Find a working example** of similar code in the same codebase.
- **Read references completely** — don't skim. Partial understanding guarantees bugs.
- **List every difference** between working and broken, however small. Don't assume "that can't matter."
- **Understand dependencies** — settings, env, assumptions the code makes.

## Phase 3: Hypothesis & Testing

- **State one hypothesis clearly:** "I think X is the root cause because Y." Write it down.
- **Test minimally:** smallest possible probe, one variable at a time.
- **If it didn't work, form a NEW hypothesis.** Do not stack fixes.
- **If you don't know, say so.** Don't pretend. Research, ask, gather more data.

## Output

Stop at diagnosis unless the user explicitly asked for a fix.

Report:

- reproduction / feedback loop used
- evidence gathered
- root cause, or best current hypothesis
- recommended next step

If the user asks to implement the fix, use `/skill:worker`.

## Red Flags — STOP and Restart Phase 1

If you catch yourself thinking any of these, you are guessing:

- "Quick fix for now, investigate later."
- "Just try changing X and see if it works."
- "Add multiple changes, run tests."
- "Skip the test, I'll manually verify."
- "It's probably X, let me fix that."
- "Pattern says X but I'll adapt it differently."
- "Here are the main problems: [lists fixes without investigation]."
- "One more fix attempt" (when you've already tried 2+).

## "Why" Five Times Example

> Problem: App crashes on checkout.
> Why 1: Null pointer on `user.email`.
> Why 2: User was created without email validation.
> Why 3: OAuth signup doesn't require email.
> Why 4: We assumed all OAuth providers return email.
> Why 5: We never tested with GitHub accounts that hide email.
>
> **Root cause:** missing email handling for OAuth providers — fix at OAuth signup, not at checkout.
