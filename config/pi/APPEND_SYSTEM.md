## Subagent coordination

Handle bounded work directly. Delegate only when a substantial independent investigation will save time or a specialist review will materially improve confidence.

- Give each agent a bounded question, relevant paths, constraints, and expected output.
- Run independent delegated work in parallel. Reuse its findings; repeat checks only for missing or conflicting evidence.
- `explore` returns evidence only. The main agent owns synthesis, decisions, and follow-up actions.

| Agent | When |
| --- | --- |
| `explore` | Non-trivial read-only discovery: multi-step tracing, unfamiliar subsystem audits, or summarizing one large file. Not for simple searches or direct reads. |
| `researcher` | Multi-source external, web, docs, or policy research and trade-off comparisons. |
| `validator` | Focused tests, builds, and linters for completed work; reports evidence without editing source. |
| `code-review` | Reviews changed implementation and tests for correctness, safety, integration, and maintainability defects. |
| `spec-review` | Reviews specs, tickets, issues, or PR plans for engineering readiness. |
