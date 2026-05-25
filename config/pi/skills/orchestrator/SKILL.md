---
name: orchestrator
description: "Load ONCE at session start. Routes the main agent to the right process skill (brainstorming/worker/debugging/polish) based on task intent and enforces verify-before-implement. Do not reload mid-session — its rules stay in context."
---

# Orchestrator

<SUBAGENT-STOP>
If you are a subagent, skip this skill.
</SUBAGENT-STOP>

Loaded once per session. Apply the rules below from context every turn.

## Route before acting

On every new user request, identify intent and load the matching process skill BEFORE any tool call (`ask_user_question`, `explore`, `read`, `grep`, web search).

| Intent                                                                | Skill                         |
| --------------------------------------------------------------------- | ----------------------------- |
| New feature, design question, "how should we…", needs a spec          | `/skill:brainstorming`        |
| Implementation with an approved spec                                  | `/skill:worker`               |
| Bug, test failure, "why doesn't this work"                            | `/skill:systematic-debugging` |
| Cleanup of recent changes                                             | `/skill:polish`               |
| Draft a ticket / issue from rough requirements (Jira, GitHub, Linear) | `/skill:ticket-writer`        |
| Review a ticket / issue for engineering readiness                     | `/skill:ticket-review`        |
| Terse output                                                          | `/skill:caveman`              |

Two skills could apply? Process first (brainstorming/debugging), then implementation.

## Multi-intent prompts

When a user prompt contains multiple top-level intents, split them into ordered steps and handle them sequentially in the order written.

- First acknowledge or perform/update the first intent, then move to the next. Do not merge intents, skip one, or pretend they are a single task.
- Within each top-level intent, still batch or parallelize independent reads, lookups, or subagent investigations.
- Do not parallelize steps that depend on each other or when the user's wording implies order.

## Red flags — stop and route

If you catch any of these thoughts, stop and reroute:

- "Just a simple question."
- "Let me explore/grep first."
- "User asked _how_, not for a feature" → still brainstorming.
- "Too small for a skill."
- "Let me check upstream docs / `~/.pi` / settings to be thorough." → STOP. If the question is about _this repo_, do not expand scope. You already have the answer.
- "I'll do these reads one at a time." → STOP. Batch independent reads into a single turn.

## Verify before implementing

Before any non-trivial change, you must know:

- **What** the change does → `ask_user_question` if unclear.
- **Where** in the code → use direct `read` / `grep` / `find` first when the user gave a path, symbol, error, or narrow search target.
- **How** (which APIs/patterns) → inspect nearby code directly for narrow areas; use `explore` only when the location is unknown or the question spans multiple subsystems.

If any is fuzzy, you're not ready.

## Subagents

| Agent         | When to dispatch                                                                                                                                                                       |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `explore`     | Broad codebase recon, unknown locations, comparative audits across many files, OR a single large file (>20K tokens) you only need to summarize (not edit). Skip for small known files. |
| `researcher`  | Multi-source external research, trade-off comparisons, "research X vs Y" — when `explore`'s single-page lookups aren't enough.                                                         |
| `code-review` | Explicit review of a diff/PR/branch/file. Read-only critique with file:line references.                                                                                                |

## Dispatch rules

Search hygiene rules (direct tools, regex combining, batching, broad-then-narrow) live in AGENTS.md and apply to everyone. The rules below are main-agent only — when to dispatch a subagent vs do it yourself.

- Do not dispatch `explore` for a single known file or a specific symbol search.
- **Exception — parallel known-file reads:** when you have ≥2 independent investigations (even on small known files), dispatch one `explore` per investigation in the same turn. pi cannot batch reads in a single turn, so parallel subagents are the only way to avoid serial latency.
- Use one bounded `explore` for comparative audits across many known files. Simple listing stays direct.
- Use `explore` for a single large file (>20K tokens) only when you need a summary, not the bytes for editing.
- **Briefing subagents.** They start with zero context from your conversation. Every prompt must include:
  - **Goal**: one sentence — what you want back.
  - **Scope**: exact file paths, symbols, or URLs in play. No "the auth file" — write the path.
  - **Constraints**: anything to skip, ignore, or stay out of (e.g. "don't read `node_modules`").
  - **Output format**: bullet list / table / JSON / file:line refs — be explicit.
- For ≥2 independent investigations, dispatch all in ONE turn so they run in parallel.
