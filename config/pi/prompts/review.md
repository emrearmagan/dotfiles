---
description: Review a branch, PR, diff, or work-in-progress change by orchestrating code-review and spec-review agents.
argument-hint: "[review target]"
---

# Review

You are orchestrating a review request.

User review request:

```text
$ARGUMENTS
```

Orchestrate the review only. The main session must not inspect the code, gather git context, read Atlas notes, fetch tickets, or write notes, except for the overview note in step 3. The specialist agents must gather their own context and use their own available tools.

Do not edit files. Do not commit. Do not change scripts/config unless the user explicitly asks.

## Process

### 1. Route the review

Identify the requested review target from the user request:

- current branch / worktree
- explicit base branch
- PR / URL / ticket / spec
- specific files or diff

Do not run git commands or Atlas-note tools just to prepare context. If a target is not explicit, pass the user's request through and let the agents infer from the current repository.

Ask a clarification only when the request cannot be routed at all.

### 2. Dispatch agents

Run the review agents in parallel whenever both reviewers are relevant.

**Code review — `code-review` agent**

Ask it to:

- gather its own git/diff context
- read existing Atlas notes and current PR comments itself when available
- review implementation correctness, safety, integration, and maintainability
- add Atlas notes itself when its own instructions allow it

Pass only the user's review request and any context already present in the conversation. Do not pre-digest the diff for it.

**Spec review — `spec-review` agent**

Ask it to:

- gather its own spec/ticket/PR description context when available
- infer ticket keys from the request, branch name, PR title/description, or commit metadata and fetch those tickets with Jira/MCP tools when available
- avoid inspecting implementation source code or full diffs unless the user explicitly requested spec-review code inspection
- review spec readiness and, only from provided summaries/descriptions, whether the described implementation has requirement gaps or scope creep
- skip or report blocked only after ticket/spec lookup was attempted or clearly impossible
- add Atlas notes itself when its own instructions allow it

Pass only the user's review request and any context already present in the conversation. Do not pre-digest the spec or diff for it.

If the user explicitly requests only one reviewer, dispatch only that agent.

### 3. Leave an overview note

When the target is a known PR and notes are not disabled, keep one Atlas file note that gives an overview of the PR:

- Use the PR URL from the request, and the head commit and overview file from the code-review output. If any of them is missing, skip the note and say why.
- Run `atlas_notes_list` for the PR. If a note whose body starts with `Overview` exists, replace its body with `atlas_notes_update`. Otherwise add one with `atlas_notes_add` on the overview file, without lines, with type `note`.
- Body: `Overview` on the first line, then 3–6 short lines: what the PR is for (spec summary), what changed and how it behaves now (change summary), and each reviewer's verdict with finding counts.
- Use only the agents' outputs. Do not inspect code or add findings.

### 4. Relay results

Do not merge, deduplicate, or rerank the agents' findings.

Output each agent's result under its own section. Preserve the substance and ordering of each agent output; only trim obvious wrapper text if needed.

If a reviewer was not run, write `Skipped` for that section.

After both sections, add a combined summary containing each reviewer's verdict and concise conclusion, followed by the total number of Atlas notes added. Derive this only from the agents' outputs; do not introduce new findings or judgments. Show the per-reviewer note counts when available.

```markdown
## Code Review

<paste the code-review agent output, or "No issues found.">

## Spec Review

<paste the spec-review agent output, "Skipped", or "No issues found.">

## Summary

- **Code Review:** <verdict and concise conclusion>
- **Spec Review:** <verdict and concise conclusion, or "Skipped">
- **Atlas notes:** <total> added (<code-review count> code review, <spec-review count> spec review)
- **Overview note:** <added, updated, or skipped (reason)>
```
