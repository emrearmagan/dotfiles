---
name: review
description: Review a branch, PR, diff, or work-in-progress change by gathering git context once, then running code and spec review axes in parallel.
---

# Review

Orchestrate a two-axis review. The current session gathers context; subagents review isolated axes.

Do not edit files. Do not commit. Do not change scripts/config unless the user explicitly asks.

## Process

### 1. Gather change context

Use git in the current session to identify a consistent review target:

- Determine base: upstream/default branch, user-provided base, or merge-base fallback.
- Gather changed-file list: `git diff --name-status <base>...HEAD`.
- Gather diff: `git diff <base>...HEAD`.
- If there are no changes, say `No changes on this branch.` and stop.

Treat generated files, vendored files, snapshots, and lockfiles as low-signal. Include them in the file list, but only inspect them deeply when the change is about generation, dependencies, or reproducibility.

### 2. Find review sources

Look for useful context without over-searching:

- Linked Jira/GitHub/Linear issue, PRD, spec, or design doc.
- PR body or branch naming clues.
- Repo standards docs such as `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, ADRs, or local conventions near changed files.

If no spec/source of truth is available, skip the spec axis and say so.

### 3. Dispatch review axes in parallel

Send both agents in the same turn when both axes are available.

**Code axis — `code-review` agent**

Pass:

- base / merge-base
- changed-file list
- diff
- relevant surrounding context already gathered
- instruction: review implementation quality only; do not run commands

Ask for defects in correctness, safety, integration, and maintainability.

**Spec axis — `spec-review` agent**

Pass:

- spec/ticket/issue/PRD content or URL/context
- changed-file list and diff summary
- instruction: check whether the change satisfies the spec, misses requirements, adds scope creep, or leaves ambiguity

If the spec itself is not ready enough to review implementation against, ask the agent to report that as the spec-axis finding.

### 4. Aggregate without mixing axes

Report axes side by side. Do not merge or rerank findings across axes; code can pass while spec fails, and spec can pass while code fails.

```markdown
## Summary
- Base: <base>
- Changed files: <count / notable files>
- Spec source: <source or none>

## Code Review
<code-review findings or "No issues found.">

## Spec Review
<spec-review findings, "Skipped: no spec source found", or "No issues found.">

## Verdict
- Code: safe / needs changes / blocked
- Spec: matches / gaps / skipped / blocked
```
