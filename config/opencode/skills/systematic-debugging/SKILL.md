---
name: systematic-debugging
description: Find the root cause before fixing — reproduce, gather evidence at each layer, form a single hypothesis, then test minimally. Use for any bug, test failure, build break, or unexpected behavior. Especially under time pressure when "one quick fix" feels obvious.
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
2. **Reproduce consistently.** Exact steps, every time. If not reproducible → gather more data, don't guess.
3. **Check recent changes.** Git diff, deploys, dep updates, config changes.
4. **In multi-component systems, instrument every boundary** *before* proposing fixes:
   - Log what data enters each component, what exits.
   - Verify env/config propagation across layers.
   - Run once to see *where* it breaks, then investigate that layer.

   Example (CI → build → signing → app):
   ```bash
   # Layer 1: workflow secrets present?
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"
   # Layer 2: env propagated to build?
   env | grep IDENTITY
   # Layer 3: keychain state?
   security find-identity -v
   # Layer 4: actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

5. **Trace data backward.** When the error is deep in the stack: where does the bad value originate? What called this with it? Keep tracing up. Fix at the source, not the symptom.

## Phase 2: Pattern Analysis

- **Find a working example** of similar code in the same codebase.
- **Read references completely** — don't skim. Partial understanding guarantees bugs.
- **List every difference** between working and broken, however small. Don't assume "that can't matter."
- **Understand dependencies** — settings, env, assumptions the code makes.

## Phase 3: Hypothesis & Testing

- **State one hypothesis clearly:** "I think X is the root cause because Y." Write it down.
- **Test minimally:** smallest possible change, one variable at a time.
- **If it didn't work, form a NEW hypothesis.** Do not stack fixes.
- **If you don't know, say so.** Don't pretend. Research, ask, gather more data.

## Phase 4: Implementation

1. **Write a failing test first.** Smallest reproduction possible. Automated if framework exists, one-off script if not.
2. **Implement one fix.** No "while I'm here" cleanup. No bundled refactoring.
3. **Verify:** test passes, no other tests broken, original issue actually resolved.
4. **If the fix doesn't work — STOP.** Count attempts. If < 3: return to Phase 1 with new data. **If ≥ 3: question the architecture (next section).**

## When 3+ Fixes Have Failed: Question Architecture

Pattern signal:
- Each fix reveals a new shared-state / coupling problem in a different place.
- Fixes require "massive refactoring" to implement.
- Each fix creates new symptoms elsewhere.

This is not a failed hypothesis — it's wrong architecture. Stop and discuss before attempting fix #4. Ask: is this pattern fundamentally sound, or are we sticking with it through inertia?

## Common Bug Patterns

| Pattern | Cause | Solution |
|---|---|---|
| Null/undefined | Missing checks | Validate at boundary |
| Race condition | Concurrency | Synchronization, transactions |
| Off-by-one | Index errors | Boundary testing |
| State mismatch | Stale data | Cache invalidation, state sync |
| Type confusion | Dynamic typing | Type checks, runtime validation |
| Resource leak | Missing cleanup | `defer`, `finally`, cleanup fns |

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

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Issue is simple, don't need process" | Simple bugs have root causes too. Process is fast for simple bugs. |
| "Emergency, no time" | Systematic debugging is faster than guess-and-check thrashing. |
| "Just try this first" | The first fix sets the pattern. Do it right from the start. |
| "I'll write the test after confirming the fix" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more attempt" (after 2+ failures) | 3+ failures = architectural problem, not a fix problem. |

## Debugging Tools by Language

### Go
```bash
dlv debug main.go            # delve debugger
go run -race main.go         # race detection
```

### Rust
```bash
RUST_BACKTRACE=1 cargo run   # full backtrace on panic
log::debug!("x = {}", x);    # log crate
```

### TypeScript / JavaScript
```bash
node --inspect-brk server.ts # Chrome DevTools attach
console.table(data);
console.trace("called from:");
```

## "Why" Five Times Example

> Problem: App crashes on checkout.
> Why 1: Null pointer on `user.email`.
> Why 2: User was created without email validation.
> Why 3: OAuth signup doesn't require email.
> Why 4: We assumed all OAuth providers return email.
> Why 5: We never tested with GitHub accounts that hide email.
>
> **Root cause:** missing email handling for OAuth providers — fix at OAuth signup, not at checkout.
