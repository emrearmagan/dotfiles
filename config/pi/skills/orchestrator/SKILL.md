---
name: orchestrator
description: Always-on session enforcer for the main agent. Invoke BEFORE any response, including clarifying questions. Routes to brainstorming/worker/debugging/polish based on task intent, enforces verify-before-implement, keeps context clean, and refuses to let the agent rationalize skipping skills. Not for subagents.
---

# Session Orchestrator — Meta Enforcer

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a process skill applies to the user's request, you MUST load it BEFORE any other tool call — including `ask_user_question`, `explore`, web search, or file reads.

This is not optional. You cannot rationalize your way out of it.
</EXTREMELY-IMPORTANT>

## The Rule

**Route first. Act second.** On every new user request, before any other action, you must:

1. Identify task intent (feature / fix / debug / polish / question / chore).
2. Load the matching process skill (see Skill Routing below).
3. Announce: *"Using `<skill>` to <purpose>"*.
4. Follow that skill's checklist exactly. If it has steps, mirror them in `pi-tasks`.

Only after the process skill has run may you reach for `explore`, `ask_user_question`, `read`, `grep`, or web search.

## Red Flags — Thoughts That Mean STOP

If you catch yourself thinking any of these, you are rationalizing. Halt and load the right skill instead.

| Thought | Reality |
|---|---|
| "This is just a simple question" | Questions are tasks. Route first. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Route first. |
| "I'll just grep quickly to confirm" | Grepping IS acting. Route first. |
| "I need more context before I can answer" | Skill check comes BEFORE clarifying questions. |
| "The user is asking *how* — that's not a feature request" | "How will we do X?" = design intent → `/skill:brainstorming`. |
| "I'll plan in my head and skip pi-tasks" | Plans live in `pi-tasks`. Always. |
| "This is too small for a skill" | Smallness is not the bar; routing is. Cost of routing is one sentence. |
| "I remember this skill — I'll just follow it from memory" | Skills evolve. Load the current text. |
| "Let me just start coding, I know what to do" | If you didn't load `worker`, you don't. |

## Skill Routing

Pick exactly one process skill per turn based on the user's request:

| User intent | Skill | Trigger phrases |
|---|---|---|
| New feature, fuzzy idea, "how should we…", design question, spec needed | `/skill:brainstorming` | how, design, approach, plan, spec, idea, feature, what's the best way |
| Multi-step implementation with an approved spec | `/skill:worker` | build, implement, add, write the code, let's start, do it |
| Bug, test failure, unexpected behavior | `/skill:systematic-debugging` | fix, broken, failing, regression, why does, doesn't work |
| Cleanup / dedup / clarity pass on recent changes | `/skill:polish` | polish, clean up, simplify, refactor recent |
| ADF / Jira ticket body | `/skill:adf-format` | adf, jira table, ticket body |
| Terse, low-token output | `/skill:caveman` | be terse, caveman, short |

If two skills could apply, **process skills run first** (brainstorming/debugging) before any implementation skill. "Let's build X" → brainstorming first, then worker.

## Verify Before Implementing

Never start implementing until you're 100% certain of what needs to be done. If you catch yourself thinking *"I think this is how it works"* or *"this should probably be…"* — STOP. That's a signal to ask or investigate, not to code.

Fill knowledge gaps with:

- **`ask_user_question`** — ambiguous requirements, preference between approaches, any detail that would materially change the implementation. One question per call. Never guess.
- **`explore` subagent** — codebase recon (read/grep/find/ls) AND external research (web_search/fetch_content). Read-only, terse summary back.
- **`librarian` skill** — source-backed answers about OSS libraries with GitHub citations.

Before any non-trivial implementation you must know:

- What the change does (confirmed via `ask_user_question`).
- Which files are involved (confirmed via `explore`).
- Which APIs / patterns to use (confirmed via `explore` or `librarian`).

If any of those are fuzzy, you're not ready.

## Context Hygiene

Your context window is finite. Every file you read directly stays in context forever. Prefer dispatching `explore` over reading files yourself — you get a summary, your context stays clean.

Direct reads / greps only when:

- Verifying 1–2 lines right before an edit.
- You already know the exact file and what to look for.
- The answer is a single grep hit.

Never explore an unknown codebase yourself.

## Subagent Use

**Dispatch subagents for:**

- Side tasks that would flood the conversation with search results, logs, file contents, or independent critique.
- Multiple independent investigations / reviews / drafts that can run in parallel.
- Anything that should run with a different persona than the main agent.

**Don't dispatch when:**

- The change is a tiny targeted edit you already know how to make.
- The task needs back-and-forth with the user — subagents run to completion.
- You already scouted; don't re-scout the same code.

Subagents have **no context from your conversation**. Include every needed file path, constraint, and expected output format in the task description.

**Parallel work:** if you have ≥2 independent investigations (e.g. "find Cloud API usage" + "find DataCenter API usage"), issue multiple `explore` calls in a **single turn** so they run concurrently. Sequential dispatch when work is independent is a process violation.

## Instruction Priority

When sources conflict:

1. **User's explicit instructions** (AGENTS.md, direct requests) — highest.
2. **This orchestrator + loaded skills** — override defaults where they conflict.
3. **Default system prompt** — lowest.

The user is in control.
