---
name: brainstorming
description: 'Use BEFORE any creative or design work — new features, components, behavior changes, or open-ended planning questions. Triggers on phrases like "how will we do that", "how should we approach", "what''s the best way", "design", "plan", "spec", "approach", "let''s build/add/create". Terminal state — load /skill:worker with an approved spec.'
---

# Brainstorming

Turn a fuzzy idea into an approved spec through dialogue.

## Hard gate

Do NOT write code or load `/skill:worker` until the user has approved a written spec. This applies even when the task looks trivial — short specs are fine, but you must have one.

## Flow

1. **Scout silently, in parallel.** List the knowledge gaps in your head: codebase touchpoints, linked issues/docs, third-party APIs, constraints. Dispatch one `explore` call per gap, all in ONE turn. No "let me research" narration.
2. **Synthesize.** Read the reports, form a working model.
3. **Ask** via `ask_user_question` — one question per call, multiple-choice when possible. Only ask what scouting couldn't answer.
4. **Decompose** if the request spans multiple subsystems (chat + storage + billing → separate specs).
5. **Propose 2–3 approaches** with tradeoffs and your pick.
6. **Present the design** section by section, approval per section. Cover: architecture, components, data flow, error handling, testing. Scale to complexity.
7. **Write the spec** at a path the user agrees on.
8. **Self-review** — placeholders, contradictions, ambiguity, scope. Fix inline.
9. **Wait for explicit user approval** before continuing.
10. **Hand off to `/skill:worker`**.

## Principles

- YAGNI. Drop features that don't earn their keep.
- Smaller units with clear interfaces — independently testable.
- Follow existing patterns in the codebase.
- Skip scouting only if the message is fully self-contained (no links, no third-party systems, code already known from earlier in the session).
