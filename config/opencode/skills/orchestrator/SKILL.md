---
name: orchestrator
description: Top-level session orchestration — verify before implementing, fill knowledge gaps with the right tool, keep context clean, and stay disciplined. Use as the always-on guide for the main agent. Not intended for subagents.
---

# Session Orchestration

## Verify Before Implementing

Never start implementing until you're 100% certain of what needs to be done.
If you catch yourself thinking "I think this is how it works" or "this should
probably be..." — STOP. That's a signal to ask or investigate, not to code.

Fill knowledge gaps with:

- **`ask_user_question` tool** — ambiguous requirements, preference between
  approaches, any detail that would materially change the implementation.
  One question per call. Never guess what the user wants.
- **`explorer` subagent** — codebase recon (read/grep/find/ls) AND external
  research (web_search/fetch_content). Read-only, terse summary back.
- **`librarian` skill** — source-backed answers about OSS libraries with
  GitHub citations.

Before any non-trivial implementation, you must know:

- What the change does (confirmed via `ask_user_question`).
- Which files are involved (confirmed via `explorer`).
- Which APIs / patterns to use (confirmed via `explorer` or `librarian`).

If any of those are fuzzy, you're not ready.

Then drive the implementation with **`/skill:worker`** — plan, implement in
small steps, verify with evidence before claiming done.

## Skill Routing

- Fuzzy idea / no spec yet → `/skill:brainstorming` (explores intent, produces a spec)
- Multi-step implementation (you have a spec) → `/skill:worker`
- Bug or test failure → `/skill:systematic-debugging`
- Polishing recently changed files → `/skill:polish`
- Terse / token-efficient output → `/skill:caveman`
- ADF (Atlassian Document Format) → `/skill:adf-format`

## Context Hygiene

Your context window is finite. Every file you read directly stays in context
forever. Prefer dispatching the `explorer` over reading files yourself — you
get a summary, your context stays clean.

Use direct reads / greps only when:

- Verifying 1–2 lines right before an edit.
- You already know the exact file and what to look for.
- The answer is a single grep hit.

Never explore an unknown codebase yourself.

## Subagent Use

**Dispatch subagents for:**

- Side tasks that would flood the conversation with search results, logs,
  file contents, or independent critique.
- Multiple independent investigations / reviews / drafts that can run in
  parallel.
- Anything that should run with a different persona than the main agent.

**Don't dispatch when:**

- The change is a tiny targeted edit you already know how to make.
- The task needs back-and-forth with the user — subagents run to completion.
- You already scouted; don't re-scout the same code.

Subagents have **no context from your conversation**. Include every needed
file path, constraint, and expected output format in the task description.

**For parallel work**, issue multiple subagent tool calls in a single turn —
they run concurrently. Use background mode when you want to keep working on
the main thread while subagents run.

