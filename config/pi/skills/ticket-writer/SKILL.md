---
name: ticket-writer
description: Draft a high-quality ticket or issue (Jira, GitHub, Linear, or generic) with structured, testable acceptance criteria. Generates ADF-ready content when the target is Atlassian. Use when the user asks to write / draft / create a ticket or issue, or convert rough requirements into one.
---

# Ticket Writer

Turn rough requirements into clear, testable tickets / issues. Practical, deterministic, never post without explicit user approval.

Adapt to the target tracker. If issue-tracker MCP tools are available (`jira_*`, `github_*`, `linear_*`, `mcp_*`), prefer them for project info, issue types, labels, custom fields, and submission. Otherwise fall back to plain output for the user to paste.

For Jira/Confluence targets requiring ADF, load `references/adf-format.md` — full markdown→ADF conversion reference. Skip ADF entirely for GitHub Issues / Linear / plain markdown trackers.

## Workflow

1. **Collect inputs.** Confirm or ask for: title, type (`Story`/`Bug`/`Task`), goal (1–2 sentences), acceptance criteria, optional context/testing/implementation notes, board/project key, labels/custom fields. Ask only for what's missing.

2. **Draft in markdown first.**

   ```markdown
   # <Title>

   ## Type
   <Story|Bug|Task>

   ## Goal
   <1–2 sentences>

   ## Acceptance Criteria
   1. <AC 1>
   2. <AC 2>

   ## Additional Context
   <optional>

   ## Testing Guidance
   <optional>

   ## Implementation Notes
   <optional>
   ```

3. **Optional AC table (ADF).** Three columns: `AC` / `DEV` / `PM`. One row per AC, `DEV` and `PM` cells empty. See `references/adf-format.md` for the table schema.

4. **Approval gate.** Confirm with the user: (a) content correct, (b) board/project, (c) approve creation. Proceed only when all three are yes.

5. **Create payload.** Convert to valid ADF, map fields, validate shape, submit, return ticket link + field summary. If submission fails with ADF errors, fix once and retry with an explanation.

## Quality bar

- **Testable**: each AC validates independently.
- **Unambiguous**: no vague verbs like "optimize" without a measurable definition.
- **Scoped**: clear in/out boundaries.
- **Actionable**: enough detail to implement without over-specifying.

## Output

- Drafting: `Preview` (markdown) + `Missing Inputs`.
- Finalization: `Final Fields` + `ADF JSON` + `Submission Result` (ticket key/link).
- Never skip the approval gate.
