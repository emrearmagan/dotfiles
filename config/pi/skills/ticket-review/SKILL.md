---
name: ticket-review
description: Review a ticket or issue (Jira, GitHub, Linear, or PM-written requirements) for completeness, clarity, and engineering readiness. Use when the user asks to review a ticket / issue, check readiness, or evaluate whether engineering can start work.
---

# Ticket Review

Review tickets as written, not as you imagine them. Identify blockers, ambiguities, and risks for an engineer who would start work today. Do not rewrite the ticket or post comments unless explicitly asked.

## Readiness criteria

A ticket is ready when it has:

1. Clear problem, goal, or user outcome.
2. Defined scope, including exclusions when relevant.
3. Testable acceptance criteria.
4. Enough context for engineering decisions.
5. Known dependencies (links, designs, systems, data).
6. Important edge cases / constraints.
7. Validation or testing expectations.

**Bugs** also need: actual vs expected, repro steps, environment, frequency, impact, evidence (logs/screenshots/IDs).

**Features/stories** also need (when relevant): actor/persona, business outcome, UX refs, API/data contracts, permissions, analytics, localization, accessibility, rollout/migration.

## Severity

- **Blocker** — engineering can't start, or would likely build the wrong thing.
- **Important** — can start, but the gap creates meaningful risk or rework.
- **Minor** — improvement, not required.

Don't overuse Blocker. If a reasonable decision is possible from existing patterns, downgrade.

## Output

Pastable as a Jira comment. Skip sections that add nothing.

```markdown
## Ticket Intent

<1–2 lines>

## Review

**[Severity]** Short issue title
Explanation: what's missing or unclear, and why it matters.
Question: the exact question to ask PM or ticket owner.

## Concrete Improvements

- <ready-to-copy improvement>

## Summary / Verdict

<Ready: why it's good enough, OR Needs Changes: concise list of blockers/gaps>
```

If there are no meaningful gaps, keep it short and mark Ready.
