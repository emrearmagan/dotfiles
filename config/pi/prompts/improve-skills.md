---
description: Scan recent conversation for friction, locate the culprit skill, and improve it (or create a new one if no skill covers the gap).
argument-hint: "[skill-name]"
---

You are running a self-correction loop on my agent skills. **Never write to AGENTS.md or CLAUDE.md** — they are read-only context. Every fix lands in a skill file.

## Step 1 — Detect friction in the recent conversation

Scan the last ~40 turns of this conversation, newest → oldest. Collect up to 3 distinct findings using this taxonomy:

| Type              | Signals                                                                      |
| ----------------- | ---------------------------------------------------------------------------- |
| **Correction**    | "no", "not like that", "I meant…", "stop doing X", user reverted your change |
| **Repetition**    | User restated the same instruction ≥2× with escalating detail                |
| **Role redirect** | "use the gh CLI, not websearch", "use X instead of Y"                        |
| **Frustration**   | "why did you do that", "???", terse negatives                                |
| **Tool misuse**   | Wrong tool picked, missing verification step, irrelevant file reads          |

For each finding capture: quote (verbatim), type, root-cause hypothesis.

If there's no friction → stop and report "no actionable signals."

## Step 2 — Locate the culprit skill

If `$1` is provided, target that skill directly. Otherwise:

List all skills:
`find ~/dotfiles -path '*/skills/*/SKILL.md' -o -path '*/commands/*.md' 2>/dev/null`
`find ~/.pi/agent -name 'SKILL.md' -o -path '*/prompts/*.md' 2>/dev/null`
Read `AGENTS.md` (and any nested `AGENTS.md` under `~/dotfiles`) to understand which skill _should_ have covered the friction.
Read the frontmatter `description:` of each candidate skill. Score each against the friction (which `description:` mentions the topic, tool, or behavior that went wrong?).
Rank the top 3 candidates. Present them with a one-line justification each.

## Step 3 — Decide: extend or create

**Extend** an existing skill if a candidate scores clearly highest and the friction is a missing rule/case inside that skill's scope.
**Create new** if no skill's `description:` covers the friction's domain, or if extending would bloat a skill past its single responsibility.

State your choice and the reason in one sentence.

## Step 4 — Propose the change

Show a unified diff for **extend**, or a full new skill body for **create**. Use this structure for new skills:

```
---
name: <kebab-case>
description: <one sentence; include trigger phrases so it's discoverable>
---

# <Title>

## When to use
## Rules
## Examples
```

For edits, prefer adding a short bullet under an existing **Rules** / **Anti-patterns** / **Examples** section over rewriting prose.

## Step 5 — Gate

Print:

```
Findings: <N>
Target: <path>
Action: extend | create
Diff: <show>

Apply? [y/N]
```

Wait for explicit `y`. On approval:
Apply the edit (or write the new file).
Run `git -C ~/dotfiles status --short` to confirm.
Print one line: `done — <path> updated`.

## Hard rules

Never write to `AGENTS.md`, `CLAUDE.md`, or any memory file.
Never edit more than one skill per invocation.
If two findings point to different skills, present both and let me pick — don't fan out.
If the friction is a one-off (no pattern, single occurrence, no clear root cause), do nothing and say so.
