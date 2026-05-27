---
name: brainstorming
description: 'Design/spec a new feature, component, or behavior change before any code. Triggers: "how should we…", "what''s the best way", "let''s build/add/create", "design", "plan", "spec". Outputs an approved spec → hands off to worker.'
---

# Brainstorming

Turn a fuzzy idea into an approved spec through dialogue. **Do not write code or load `worker` until the user approves a written spec.** Short specs fine — one must exist.

## Flow

1. **Scout in parallel.** Identify gaps (code, docs, APIs, constraints). Dispatch independent `explore` agents in one turn. Skip when the question is self-contained or a direct `read`/`grep` answers it.
2. **Ask** what scouting couldn't answer — one `ask_user_question` per call, multiple-choice when possible.
3. **Decompose** if the request spans subsystems → separate specs.
4. **Propose 2–3 approaches** with tradeoffs and your pick.
5. **Present the design** section by section (architecture, components, data flow, errors, testing), approval per section.
6. **Write the spec** at a path the user agrees on.
7. **Self-review** for placeholders, contradictions, scope drift. Fix inline.
8. **Wait for explicit approval**, then hand off to `worker`.

## Principles

- YAGNI. Drop features that don't earn their keep.
- Smaller units with clear interfaces.
- Follow existing codebase patterns.
