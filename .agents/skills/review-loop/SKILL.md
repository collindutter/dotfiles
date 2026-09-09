---
name: review-loop
description: Iteratively cut yap from the current changes, review them with the review skill, fix the findings, and commit, repeating until the reviewer is reasonably satisfied. Use when the user wants to harden a PR or branch before merging.
allowed-tools: Bash Read Edit Write Grep Glob
---

# Review Loop

Run an automated yap-review-fix-commit loop on the current changes until a
review sub-agent comes back with a reasonable level of satisfaction.

Arguments (optional): $ARGUMENTS

- May contain extra context to forward to the reviewer (e.g. a base branch or
  areas to focus on).
- If no arguments are given, review the diff against the base branch.
- The review model is pinned in `subagents.agentOverrides.reviewer.model`
  (`~/.pi/agent/settings.json`), not per invocation.

## Loop

Repeat the following until the stopping condition is met. Cap at **5
iterations** to guarantee termination.

1. **Cut yap.** Invoke the `yap` skill, which calls the `subagent` tool with the
   `yap-cutter` agent over the same diff. It edits comments, docstrings, and
   prose only, so the reviewer spends its budget on correctness instead of
   comment bloat. Let it finish before step 2; it writes to the same tree the
   reviewer reads. Skip it on an iteration whose fixes added no comments or
   prose.

2. **Review.** Invoke the `review` skill, which calls the `subagent` tool with
   the `reviewer` agent over the current changes (the diff against the base
   branch, which now includes any fixes from prior iterations). The reviewer
   runs in an isolated context and streams its progress into this session.
   Forward any context from `$ARGUMENTS`. Do not review the code yourself; let
   the reviewer subagent do it.

   `pi-subagents` also ships a `/review-loop` prompt and a `/parallel-review`
   prompt. Those are separate, parent-orchestrated workflows. This skill is the
   merge-base-scoped commit loop; do not mix the two in one run.

3. **Triage findings.** Classify each finding by severity:
   - **Actionable**: bugs, logic errors, security issues, error-handling gaps,
     or correctness problems introduced by the changes.
   - **Non-actionable**: subjective style preferences, nitpicks, out-of-scope
     suggestions, or comments about pre-existing code not touched by the diff.

   Residual yap findings are actionable only if the yap pass left something the
   reviewer can point at concretely. Do not relitigate comment wording.

4. **Check the stopping condition** (see below). If met, stop and report.

5. **Fix.** Address every actionable finding. Make focused edits that resolve
   the underlying problem, not just the symptom the reviewer named. If a
   finding is unclear or you disagree, note your reasoning instead of making a
   change you believe is wrong.

6. **Commit.** Stage only the files you changed in this iteration, including the
   yap pass edits, and commit with a conventional-commit message describing the
   fixes (e.g. `fix: handle nil response in parser`). When the yap pass was the
   only change, commit it on its own as `docs: cut yap`. Do not commit unrelated
   files.

7. **Repeat** from step 1 so the next review sees the updated diff.

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
- What the yap pass cut, in one line per iteration.
- The final review verdict (what made it stop).
- Any actionable findings left unaddressed and why.
- Any findings you intentionally declined to fix, with reasoning.
