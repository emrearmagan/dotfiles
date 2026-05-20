# Verification Reference

Detailed claim→evidence requirements and rationalization catchers for the worker skill.

## Claim → Evidence Required

| Claim             | Required evidence                 | Not enough                  |
| ----------------- | --------------------------------- | --------------------------- |
| Tests pass        | Test command output: 0 failures   | "Should pass", earlier run  |
| Build succeeds    | Build command exit 0              | Linter passed               |
| Bug fixed         | Original repro now passes         | Code changed, "looks right" |
| Linter clean      | Linter output: 0 errors           | Partial check               |
| Requirements met  | Line-by-line checklist vs plan    | Tests pass                  |
| Subagent finished | `git diff` shows expected changes | Agent reports success       |

## Red Flags — STOP

If you catch yourself doing any of these, you are about to claim without evidence:

- Using "should", "probably", "seems to", "looks like".
- "Great!", "Perfect!", "Done!" before running anything.
- About to commit/PR without running tests.
- Trusting a subagent's "success" report without inspecting the diff.
- Partial verification ("linter passed so build works").
- "Just this once" / "I'm tired" / "I'm confident".

## Rationalizations

| Excuse                    | Reality                        |
| ------------------------- | ------------------------------ |
| "Should work now"         | Run the verification.          |
| "I'm confident"           | Confidence ≠ evidence.         |
| "Just this once"          | No exceptions.                 |
| "Linter passed"           | Linter ≠ compiler ≠ tests.     |
| "Agent said success"      | Verify the diff independently. |
| "Partial check is enough" | Partial proves nothing.        |
