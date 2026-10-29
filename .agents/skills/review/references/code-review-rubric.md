# Adversarial code review rubric

How to review a diff adversarially. It does not depend on any agent harness or
tool, so a delegated reviewer, a reviewing agent, or a person can follow it.

Your job is to break confidence in the change, not to validate it. Review as if
you are looking for the strongest reasons this diff should not ship. Assume it
fails in some subtle, costly, or user-visible way until the code shows
otherwise.

Be aggressive but grounded. A finding you cannot support from the code is
worse than no finding, because it costs the author time and erodes trust in the
next real one. If the diff holds up, say so and return no findings. Never
manufacture weak findings to satisfy the framing.

## Scope

- Review only what the diff introduces or newly exposes. Ignore pre-existing
  issues in unchanged code, unless the diff now depends on them or makes them
  reachable.
- The review is read-only: no edits, staging, or builds. Check claims by
  reading source. When a claim can only be confirmed by running code, say so.
- Unfamiliar APIs, libraries, or versions are not evidence of a bug. Your
  training data may be stale. Mark such findings `unverifiable` instead of
  inventing deprecations or misuse.

## Method

1. Read the diff, then the PR description and any linked issues or PRs. The
   description states what the change claims to do, and that claim is what you
   attack.
2. Read the changed files around each hunk. Also read callers and callees the
   diff touches, since regressions often surface in unchanged code that
   depends on changed code.
3. In two or three sentences, state what the change is trying to do and why
   the approach is plausible. This is the steelman. It keeps you from
   attacking a change the author didn't make.
4. Identify the failure the diff is meant to eliminate. Follow the bad value or
   state back to where it originates, then check whether the fix reaches it.
5. Try to break it. For each changed path, trace hostile and degraded inputs:
   empty, null, huge, malformed, duplicated, out of order, concurrent, retried,
   timed out, partially applied. Look for violated invariants, missing guards,
   and assumptions that stop holding under stress.
6. Try to refute each candidate finding before you report it. Look for the
   guard, validation, test, or caller contract that would make it a non-issue.
   Drop the finding if you find one. If you can't settle it, report it with
   honest confidence and say what would settle it.

### Attack surface

Weight expensive, dangerous, or hard-to-detect failures:

- Auth, permissions, tenant isolation, trust boundaries, injection
- Data loss, corruption, duplication, irreversible state changes
- Partial failure, retries, idempotency, rollback safety
- Races, ordering assumptions, stale state, re-entrancy
- Empty state, null, timeouts, degraded dependencies
- Version skew, schema drift, migrations, breaking API or wire changes
- Failures that are masked, such as broad exception handlers, silent
  defaults, or retries that let a broken path report success
- Observability gaps that hide failure or block recovery
- Tests that pass without exercising the change, or that assert internal
  calls instead of behavior

### Stated intent

Give no credit for good intent, partial fixes, or follow-up work that is only
promised. If the description defers something to a linked PR or issue that
exists, acknowledge the plan and judge whether shipping this half alone is
safe. If the follow-up is only mentioned, treat the gap as real. When the
description explains a surprising choice, engage with its reasoning. Press
only when the reasoning doesn't hold up against what the diff actually does.

## Finding bar

Report only material findings. Every finding must answer:

1. **Scenario.** The concrete input, sequence, or state that triggers it.
2. **Trace.** How that scenario moves through the cited code to the failure.
3. **Impact.** What breaks, for whom, and how visibly.
4. **Fix.** The concrete change that removes the risk, at its cause.

If you can't fill in the scenario and trace, the finding isn't ready. Drop it
or mark it `unverifiable`. When a step rests on inference rather than code
you read, say so.

Rate each finding:

- **Severity:** `high` (exploitable, data-losing, or breaks a core path),
  `medium` (wrong behavior on a realistic path), `low` (an edge case with
  limited impact), or `unverifiable`.
- **Confidence:** `high`, `medium`, or `low`.

Skip style, formatting, naming preferences, generic "add tests" advice,
speculative performance concerns, and suggestions to switch libraries. One
strong finding beats five weak ones. LLMisms and Yap below are the exception.
They have their own lighter bar and never affect the verdict.

## Sections

### Problem framing

Is the diff aimed at the real defect? A clean change in the wrong place still
leaves the bug. Look for:

- A fix applied downstream of the cause, such as a guard for a value that
  should never have been produced, or a retry around a deterministic failure.
- A mismatch between the reported failure and the fixed one.
- A special case bolted onto a rule that is itself wrong.
- Machinery built to live with a constraint the diff could have lifted.
- Tests that pin the workaround, so the real defect can't be observed.

Name where you believe the cause lives and the evidence that points there. If
the framing holds up, say so in one line.

### Breakage

Bugs, security holes, and failure-handling gaps from the attack surface. This
is the core of the review.

### Maintainability

Only structural problems that will cause defects or block change, such as a
wrong abstraction, class-as-namespace, unrelated responsibilities in one unit,
duplicated logic that will drift, inconsistent call sites, the same arguments
threaded through many helpers, over- or under-engineering, or a leaky API.

### LLMisms

Patterns characteristic of machine-authored diffs, judged on added or modified
lines only. Report each pattern once with a few representative `file:line`
examples, not once per occurrence. If the diff is clean, say so in one line.

- Superiority naming: `enhanced_*`, `improved_*`, `*_v2`, `NewFooManager`.
  Whatever is new today will be old later.
- Unrequested backward compatibility: shims, aliases, or dual code paths for
  interfaces with no remaining callers, absent a stated need.
- Defensive fallbacks that mask failure: broad exception handlers, silent
  defaults, or retries. Report under Breakage instead when you can show a
  scenario where they hide a real failure.
- Tests coupled to the implementation: asserting internal calls instead of
  observable behavior, or mocking the unit under test.

### Yap

Yap is comment, docstring, and prose bloat: words written for the writer, not
the reader. Its definition lives in one place:

    /Users/collindutter/.agents/skills/yap/references/yap-field-guide.md

Read that file for the patterns and the keep test. Report yap as one finding
with a handful of representative `file:line` examples and the pattern each
hits. A separate yap pass may already have cleaned the diff. When it reads
clean, say so in one line. The reviewer only reports yap. The `yap` skill cuts
it.

A comment the diff made false is a breakage finding, not yap.

## Output format

### Verdict
`SHIP`, `ITERATE`, or `RETHINK`, then one or two sentences in the voice of a
ship/no-ship call, not a neutral recap.

- `SHIP`: no `high` or `medium` findings.
- `ITERATE`: at least one `high` or `medium` finding, fixable in place.
- `RETHINK`: the problem framing is wrong, or the approach can't be made safe
  without redesign.

### Understanding
The two- or three-sentence steelman from the method.

### Problem framing
One line if it holds up. Otherwise the suspected cause location and evidence.

### Breakage
Ordered by severity, then confidence:

- `file.ts:42-48` **Title** (`high`, confidence `medium`)
  Scenario, trace, impact, fix.

### Maintainability
Same shape, or "None."

### LLMisms
- **Pattern name.** Why it hurts, with representative locations
  (`file.ts:12`, `file.ts:88`). One entry per pattern, or one line if clean.

### Yap
- **Yap.** Representative locations and the guide pattern each hits, or one
  line saying the diff reads clean.

### Refuted
Candidate findings you investigated and dropped, one line each with the
evidence that cleared them. This shows what was checked.

### Coverage
Files and paths you read in full, and anything relevant you didn't examine,
such as unread callers, generated code, or behavior that needs execution to
confirm.
