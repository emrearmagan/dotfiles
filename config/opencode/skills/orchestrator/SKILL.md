---
name: orchestrator
description: 'Load ONCE at session start. Routes the main agent to the right process skill (brainstorming/worker/debugging/polish) based on task intent and enforces verify-before-implement. Do not reload mid-session — its rules stay in context.'
---

# Orchestrator

<SUBAGENT-STOP>
If you are a subagent, skip this skill.
</SUBAGENT-STOP>

Loaded once per session. Apply the rules below from context every turn.

## Route before acting

On every new user request, identify intent and load the matching process skill BEFORE any tool call (`ask_user_question`, `explore`, `read`, `grep`, web search).

| Intent | Skill |
|---|---|
| New feature, design question, "how should we…", needs a spec | `/skill:brainstorming` |
| Implementation with an approved spec | `/skill:worker` |
| Bug, test failure, "why doesn't this work" | `/skill:systematic-debugging` |
| Cleanup of recent changes | `/skill:polish` |
| Draft a ticket / issue from rough requirements (Jira, GitHub, Linear) | `/skill:ticket-writer` |
| Review a ticket / issue for engineering readiness | `/skill:ticket-review` |
| Terse output | `/skill:caveman` |

Two skills could apply? Process first (brainstorming/debugging), then implementation.

## Red flags — stop and route

If you catch any of these thoughts, route first:

- "Just a simple question."
- "Let me explore/grep first."
- "User asked *how*, not for a feature" → still brainstorming.
- "Too small for a skill."

## Verify before implementing

Before any non-trivial change, you must know:

- **What** the change does → `ask_user_question` if unclear.
- **Where** in the code → `explore` (one subagent dispatch, not direct reads).
- **How** (which APIs/patterns) → `explore` or library docs.

If any is fuzzy, you're not ready.

## Subagents

- Prefer dispatching `explore` over reading files yourself — your context stays clean.
- ≥2 independent investigations → dispatch all `explore` calls in ONE turn.
- Subagents have no conversation context — pass every needed file path, constraint, and expected output format in the task description.
