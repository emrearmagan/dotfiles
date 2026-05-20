---
name: brainstorming
description: Use this BEFORE any creative work — creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements, and design before implementation. The terminal state is loading `/skill:worker` with an approved spec.
---

# Brainstorming Ideas Into Designs

Turn a fuzzy idea into a fully formed design + spec through natural dialogue. The output is a written spec the user has approved, ready for `/skill:worker` to plan and execute.

## Hard Gate

**Do NOT write code, scaffold files, or load `/skill:worker` until you have presented a design and the user has approved it.** This applies to every project regardless of perceived simplicity.

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this. A todo list, a single utility function, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple work), but you MUST present it and get approval.

## Checklist (do in order)

1. **Explore project context** — recent commits, related files, conventions. Use the `explorer` subagent for unknown codebases; don't read files yourself.
2. **Ask clarifying questions, one at a time** — use `ask_user_question` if available. Prefer multiple-choice over open-ended. Focus on purpose, constraints, success criteria.
3. **Scope check** — if the request describes multiple independent subsystems (e.g. "chat + storage + billing"), flag it immediately and help decompose into sub-projects, each with its own spec.
4. **Propose 2–3 approaches** — with tradeoffs, your recommendation, and why.
5. **Present design sections** — scale each section to its complexity. Cover: architecture, components, data flow, error handling, testing. Get approval after each section.
6. **Write the spec** — ask the user where they want it saved if it's not obvious from the project. Commit it.
7. **Self-review the spec** — placeholder scan, internal consistency, scope, ambiguity. Fix inline.
8. **User reviews the written spec** — wait for explicit approval before continuing.
9. **Hand off to `/skill:worker`** — that skill plans and executes. The ONLY skill you invoke next.

## Asking Questions

- **One question per message.** No batching.
- **Multiple choice when possible** — easier to answer than open-ended.
- **Focus on understanding** — purpose, constraints, success criteria, edge cases.
- **Be flexible** — go back and clarify when something doesn't make sense.

## Proposing Approaches

- Always 2–3 approaches, never one.
- Lead with your recommendation and the reasoning.
- Trade-offs explicit: what does each option give up?
- YAGNI ruthlessly — drop unnecessary features.

## Presenting the Design

- Section by section, with approval per section.
- Scale to complexity: a few sentences for simple bits, ~200-300 words for nuanced ones.
- Cover: architecture, components, data flow, error handling, testing.

**Design for isolation and clarity:**

- Smaller units with clear purpose, well-defined interfaces, independently testable.
- For each unit, answer: what does it do, how do you use it, what does it depend on?
- Can someone understand a unit without reading its internals? If not, boundaries need work.

**In existing codebases:**

- Explore current structure before proposing changes. Follow existing patterns.
- Include targeted improvements as part of the design where existing code blocks the work — but don't propose unrelated refactoring.

## Spec Self-Review

After writing the spec, look at it with fresh eyes:

1. **Placeholder scan** — any "TBD", "TODO", incomplete sections, vague requirements? Fix them.
2. **Internal consistency** — sections contradict each other? Architecture match feature descriptions?
3. **Scope** — focused enough for a single plan, or needs decomposition?
4. **Ambiguity** — could any requirement be interpreted two ways? Pick one, make it explicit.

Fix inline. No need to re-review — just fix and move on.

## User Review Gate

After the self-review:

> "Spec written and committed to `<path>`. Please review it and let me know if you want changes before we move to implementation."

Wait for the user's response. If they request changes, make them and re-run self-review. Only proceed once they approve.

## Transition

Once the spec is approved, load `/skill:worker` and pass the spec path. That skill writes the plan and drives implementation.

## Key Principles

- **One question at a time.**
- **Multiple choice preferred.**
- **YAGNI ruthlessly.**
- **Explore 2–3 alternatives**, never settle for one.
- **Incremental validation** — approval per section, then per spec.
- **Be flexible** — clarify when something doesn't make sense.
