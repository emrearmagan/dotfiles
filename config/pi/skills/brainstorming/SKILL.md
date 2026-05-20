---
name: brainstorming
description: 'Use BEFORE any creative or design work — new features, components, behavior changes, or open-ended planning questions. Triggers on phrases like "how will we do that", "how should we approach", "what''s the best way", "design", "plan", "spec", "approach", "idea for", "let''s build/add/create", or any fuzzy request without an approved spec. Explores intent, requirements, and design through dialogue. Terminal state — load /skill:worker with an approved spec.'
---

# Brainstorming Ideas Into Designs

Turn a fuzzy idea into a fully formed design + spec through natural dialogue. The output is a written spec the user has approved, ready for `/skill:worker` to plan and execute.

## Hard Gate

**Do NOT write code, scaffold files, or load `/skill:worker` until you have presented a design and the user has approved it.** This applies to every project regardless of perceived simplicity.

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this. A todo list, a single utility function, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple work), but you MUST present it and get approval.

## Checklist (do in order)

1. **Scout silently, in parallel.** Before any user-facing text, privately enumerate what you need to know to design well, then dispatch the research as concurrent `explore` calls in a single turn. (See "Scout Phase" below — this is non-optional.)
2. **Synthesize internally.** Read the explore reports. Form a working mental model. Do NOT narrate "let me explore" or "I'll research" to the user — they don't care about your process; they care about the result.
3. **Ask clarifying questions, one at a time** — use `ask_user_question` if available. Prefer multiple-choice over open-ended. Focus on purpose, constraints, success criteria. Only ask things scouting could not answer.
4. **Scope check** — if the request describes multiple independent subsystems (e.g. "chat + storage + billing"), flag it immediately and help decompose into sub-projects, each with its own spec.
5. **Propose 2–3 approaches** — with tradeoffs, your recommendation, and why.
6. **Present design sections** — scale each section to its complexity. Cover: architecture, components, data flow, error handling, testing. Get approval after each section.
7. **Write the spec** — ask the user where they want it saved if it's not obvious from the project. Commit it.
8. **Self-review the spec** — placeholder scan, internal consistency, scope, ambiguity. Fix inline.
9. **User reviews the written spec** — wait for explicit approval before continuing.
10. **Hand off to `/skill:worker`** — that skill plans and executes. The ONLY skill you invoke next.

## Scout Phase (Step 1, in detail)

The user's first message rarely contains everything you need. Before you can ask a useful question or propose a design, you must close the obvious knowledge gaps yourself — silently and in parallel.

### Enumerate gaps (in your head, not out loud)

Ask yourself, every time:

- **Codebase**: which files/modules does this touch? What patterns/abstractions exist already?
- **External references**: any linked GitHub issue, RFC, doc, ticket, or Slack thread in the user's message? Each is a separate fetch.
- **External APIs / libraries / standards**: any third-party system or library mentioned? Each requires doc lookup.
- **History**: any prior attempts, related commits, or recent regressions in this area?
- **Constraints**: tests, lint config, types, runtime version — anything that bounds the design space?

Each distinct gap becomes one `explore` task.

### Dispatch in parallel

If you have ≥2 independent gaps, issue **all** the `explore` calls in a **single turn**. Sequential dispatch when gaps are independent is a process violation — it costs real time and adds nothing.

Pattern: a task that mentions a linked issue, an existing subsystem to extend, and an external API splits into three independent investigations — one to fetch the issue, one to map the current code, one to research the external API. Three independent investigations → one turn with three `explore` calls.

### Silence rule

Do not announce "I'm going to explore X and Y." The user already knows. Dispatch, wait, synthesize, then come back with a substantive first message: design questions, scope flags, or an approach proposal grounded in what you learned. The user's experience should be: *they ask → you come back with something useful*, not *they ask → you narrate your plan → you research → you finally respond*.

Brief announcements like "Dispatching scouts in parallel" are acceptable but optional. Long narration is not.

### When to skip scouting

Skip only when **all** of these are true:

- The user's message contains a complete spec (no ambiguity).
- No external references, links, or third-party systems are involved.
- You already know the relevant code from earlier in the session.

Otherwise: scout first.

## Asking Questions

**Always use the `ask_user_question` tool — never ask in plain prose.** The tool is the project's standard for clarifications; prose questions break the UX and don't track answers.

- **One question per `ask_user_question` call.** No batching multiple questions into one call.
- **Multiple choice when possible** — easier to answer than open-ended. The tool supports options; use them.
- **Focus on understanding** — purpose, constraints, success criteria, edge cases.
- **Only ask what scouting could not answer.** If you can read the answer from the code or a fetched doc, don't ask.
- **Be flexible** — call `ask_user_question` again to clarify when an earlier answer raises new questions.

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
