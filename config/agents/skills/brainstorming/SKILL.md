---
name: brainstorming
description: 'Explore a design when the user asks to brainstorm, design, or plan, or when materially unclear requirements prevent implementation. Skip for clear implementation requests.'
---

# Brainstorming

Resolve the decisions needed for a useful design. Do not turn clear implementation requests into a design workflow.

## Flow

1. **Identify the gap.** Use the context already available. Read or search only to answer unresolved questions relevant to the design.
2. **Resolve material choices.** Ask when a missing requirement would change the result. Compare alternatives only when there are real tradeoffs, and recommend one.
3. **Present the smallest useful design inline.** Reuse existing code and conventions. Write a separate spec only when requested or when the work needs a durable reference.
4. **Continue within the request.** If implementation was requested, proceed once substantive decisions are resolved. Otherwise return the design. A written spec or separate approval is not a prerequisite by itself.

## Principles

- YAGNI. Drop features that don't earn their keep.
- Smaller units with clear interfaces.
- Follow existing codebase patterns.
