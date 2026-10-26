# Verification

Choose checks that show whether the requested behavior works. Use the project's existing commands and test setup where possible.

## Choose checks

Start with a focused check, then cover anything important it leaves out.

| Change | Useful check |
| --- | --- |
| Behavior | Test the expected result through an interface users or callers use, including important error and edge cases. |
| Bug fix | When practical, confirm the regression test fails because of the original bug, then passes with the fix. |
| Shared interface | Check affected callers as well as the component itself. |
| UI | Try the interaction and inspect the result where automated tests don't cover it. |
| Docs or configuration | Parse, load, check links, or inspect rendered output as appropriate. |

- Test the requested behavior and the promises the code makes to its callers.
- Avoid tests that copy the production algorithm, depend on private call order, or merely match wording.
- Run broader checks when local instructions require them or the change could affect more of the project.

## Read results

- Confirm the command finished, what it tested, and whether anything was skipped. A successful exit alone doesn't prove the behavior works.
- Make sure the check exercised the changed code and didn't silently select fewer tests than intended.
- Understand a failure before editing code to make it pass. Use `systematic-debugging` when the cause is unclear.
- If a check can't run, record the exact reason. Use another check if it answers part of the question, and say what it leaves untested.
- Distinguish failures caused by your change from existing failures and checks you couldn't run.
- Don't weaken tests or remove required validation to get a passing result.

## Reuse results

- Keep a result while the code, configuration, dependencies, test data, and environment it depends on are unchanged.
- After editing, rerun the checks the edit could affect. Keep unrelated passing results.
- For another agent's checks, review what ran, what it covered, the result, and any caveats. Repeat only what's missing, questionable, or affected by later changes.
- Before finishing, check that the results cover the whole request and review your diff. Fill remaining gaps and report what passed, failed, couldn't run, or remains untested.
