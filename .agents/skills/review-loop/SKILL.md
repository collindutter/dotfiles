---
name: review-loop
description: Iteratively cut yap from the current changes, review them with the review skill, fix the findings, and commit, repeating until the reviewer is reasonably satisfied. Use when the user wants to harden a PR or branch before merging.
allowed-tools: Bash Read Edit Write Grep Glob
---

# Review Loop

Loop yap, review, fix, commit on the current changes until a stopping condition
below holds.

Arguments (optional): $ARGUMENTS

- Extra context for the reviewer, e.g. a base branch or focus areas.
- None given: review the diff against the base branch.
- The review model is pinned in `subagents.agentOverrides.reviewer.model`
  (`~/.pi/agent/settings.json`).

## Running unattended

The loop runs to a stopping condition without check-ins. Ending a turn with no
tool call stops the loop, so avoid these:

- A summary of an iteration that announces the next step instead of taking it.
- Offering to continue, or asking whether to fix a finding you can triage
  yourself.
- Stopping to report because an iteration or milestone finished.

Put status notes in the same message as the next tool call. Stop only on a
stopping condition, or when a decision truly needs the user. While a subagent
runs, wait for its result; a running subagent means the iteration isn't done.

## Loop

Cap at 5 iterations.

1. **Cut yap.** Run the `yap` skill (`yap-cutter` over the same diff). It edits
   comments, docstrings, and prose only, so the reviewer spends its budget on
   correctness. Let it finish first, since both read the same tree. Skip it on
   iterations whose fixes added no comments or prose.

2. **Review.** Run the `review` skill (`reviewer` over the diff against the
   base branch, which now includes earlier fixes). Forward `$ARGUMENTS`. Leave
   the grading to the reviewer.

   `pi-subagents` also ships `/review-loop` and `/parallel-review` prompts.
   Those are separate parent-orchestrated workflows; don't mix them into this
   run.

3. **Triage.** The reviewer reports everything; you filter.
   - **Actionable**: bugs, logic errors, security issues, error-handling gaps,
     or correctness problems the changes introduce, plus design findings you
     agree with.
   - **Non-actionable**: style preferences, nitpicks, out-of-scope suggestions,
     comments on code the diff didn't touch.

   Residual yap is actionable only when the reviewer points at something
   concrete. Don't relitigate comment wording.

4. **Check the stopping condition.** If met, stop and report.

5. **Fix.** Address each actionable finding at its cause, not just the symptom
   named. If you disagree with one, note why instead of making a change you
   think is wrong.

6. **Commit.** Stage only files changed this iteration, including yap edits.
   Conventional-commit message describing the fixes
   (`fix: handle nil response in parser`). A yap-only iteration commits as
   `docs: cut yap`.

7. **Repeat** from step 1.

## Stopping condition

- No actionable findings remain.
- Remaining findings are all ones you declined, with reasons, and another
  review wouldn't change that.
- 5 iterations are spent.
- The same finding survives two fix attempts, or the reviewer oscillates
  between contradictory suggestions. Surface the disagreement.

## Report

Lead with the verdict that ended the loop, then:

- Iterations run and each one's commits.
- What yap passes cut, one line per iteration.
- Actionable findings left open, and why.
- Findings declined, with reasons.
