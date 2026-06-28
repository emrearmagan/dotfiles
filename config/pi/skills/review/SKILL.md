---
name: review
description: Review a branch, PR, diff, or work-in-progress change by gathering git context once, then running code and spec review axes in parallel.
---

# Review

Orchestrate a two-axis review. The current session gathers context, manages local branch notes, and aggregates results; subagents review isolated axes.

Do not edit files. Do not commit. Do not change scripts/config unless the user explicitly asks.

## Process

### 1. Gather change context

Use git in the current session to identify a consistent review target:

- Determine base: upstream/default branch, user-provided base, or merge-base fallback.
- Gather changed-file list: `git diff --name-status <base>...HEAD`.
- Optionally gather a compact diff stat: `git diff --stat <base>...HEAD`.
- Do not gather full diff hunks by default; review subagents should inspect the worktree/diff themselves.
- If there are no changes, say `No changes on this branch.` and stop.

Treat generated files, vendored files, snapshots, and lockfiles as low-signal. Include them in the file list, but only inspect them deeply when the change is about generation, dependencies, or reproducibility.

### 2. Read branch notes

Read existing local notes before dispatching review axes.

Prefer the `branch_notes_list` tool. If unavailable, use:

```bash
branch-notes list --json
```

Treat existing notes as prior findings, not truth:

- include relevant notes in subagent context
- validate whether they still apply
- avoid duplicate findings and duplicate notes
- mention relevant existing notes in the final summary

### 3. Find review sources

Look for useful context without over-searching:

- Linked Jira/GitHub/Linear issue, PRD, spec, or design doc.
- PR body or branch naming clues.
- Repo standards docs such as `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, ADRs, or local conventions near changed files.

If no spec/source of truth is available, skip the spec axis and say so.

### 4. Dispatch review axes in parallel

Send both agents in the same turn when both axes are available.

**Code axis — `code-review` agent**

Pass:

- base / merge-base
- changed-file list/name-status
- compact diff stat, if useful
- relevant surrounding context already gathered
- relevant existing branch notes
- instruction: inspect the worktree/diff yourself; review implementation quality only; do not write notes

Ask for defects in correctness, safety, integration, and maintainability.

**Spec axis — `spec-review` agent**

Pass:

- spec/ticket/issue/PRD content or URL/context
- changed-file list/name-status and compact diff stat, if useful
- relevant existing branch notes
- instruction: inspect changed files only as needed; check whether the change satisfies the spec, misses requirements, adds scope creep, or leaves ambiguity; do not write notes

If the spec itself is not ready enough to review implementation against, ask the agent to report that as the spec-axis finding.

### 5. Write branch notes

After aggregating findings, write local notes for actionable findings that should be saved for later review.

Prefer `branch_notes_add`. If unavailable, use `branch-notes add`.

Only write notes for concrete findings tied to a specific changed file and line. Do not write notes for style preferences, broad summaries, speculative risks, or duplicates of existing notes.

After writing notes, read notes again and verify the expected notes exist.

### 6. Aggregate without mixing axes

Report axes side by side. Do not merge or rerank findings across axes; code can pass while spec fails, and spec can pass while code fails.

```markdown
## Summary
- Base: <base>
- Changed files: <count / notable files>
- Spec source: <source or none>
- Branch notes: <existing count>, <new notes written count>

## Code Review
<code-review findings or "No issues found.">

## Spec Review
<spec-review findings, "Skipped: no spec source found", or "No issues found.">

## Verdict
- Code: safe / needs changes / blocked
- Spec: matches / gaps / skipped / blocked
```
