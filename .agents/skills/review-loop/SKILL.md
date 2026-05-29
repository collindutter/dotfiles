---
name: review-loop
description: Iteratively review the current changes with the review skill, fix the findings, and commit, repeating until the reviewer is reasonably satisfied. Use when the user wants to harden a PR or branch before merging.
allowed-tools: Bash Read Edit Write Grep Glob
---

# Review Loop

Run an automated review-fix-commit loop on the current changes until a review
sub-agent comes back with a reasonable level of satisfaction.

Arguments (optional): $ARGUMENTS

- May contain extra context to forward to the reviewer (e.g. a base branch, a
  model override like `--provider/--model`, or areas to focus on).
- If no arguments are given, review the diff against the base branch.

## Loop

Repeat the following until the stopping condition is met. Cap at **5
iterations** to guarantee termination.

1. **Review.** Invoke the `review` skill to spawn a review sub-agent over the
   current changes (the diff against the base branch, which now includes any
   fixes from prior iterations). Forward any context from `$ARGUMENTS`. Do not
   review the code yourself; let the sub-agent do it.

2. **Triage findings.** Classify each finding by severity:
   - **Actionable**: bugs, logic errors, security issues, error-handling gaps,
     or correctness problems introduced by the changes.
   - **Non-actionable**: subjective style preferences, nitpicks, out-of-scope
     suggestions, or comments about pre-existing code not touched by the diff.

3. **Check the stopping condition** (see below). If met, stop and report.

4. **Fix.** Address every actionable finding. Make focused edits that resolve
   the underlying problem, not just the symptom the reviewer named. If a
   finding is unclear or you disagree, note your reasoning instead of making a
   change you believe is wrong.

5. **Commit.** Stage only the files you changed in this iteration and commit
   with a conventional-commit message describing the fixes (e.g.
   `fix: handle nil response in parser`). Do not commit unrelated files.

6. **Repeat** from step 1 so the next review sees the updated diff.

## Stopping condition

Stop the loop when any of these is true:

- The reviewer reports **no actionable findings** (only non-actionable items,
  or nothing at all). This is the target "reasonable satisfaction" state.
- The remaining findings are all ones you have deliberately declined to fix,
  with reasoning, and re-reviewing would not change that.
- You hit the **5-iteration cap**.
- The same finding recurs unchanged after you attempted a fix twice, or the
  reviewer oscillates between contradictory suggestions. In that case, stop and
  surface the disagreement rather than churning.

## Report

When the loop ends, summarize:

- How many iterations ran and the commits created in each.
- The final review verdict (what made it stop).
- Any actionable findings left unaddressed and why.
- Any findings you intentionally declined to fix, with reasoning.

Then show a non-blocking alert that the loop finished:
`alerter --title "Pi" --message "Review loop done: <verdict>" --timeout 30 >/dev/null 2>&1 &`
