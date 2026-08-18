---
name: draft-review-comments
description: Post a DRAFT (pending) GitHub PR review made of separate inline review comments anchored to the diff, each with an AI-assisted disclosure, GitHub deep-link permalinks that render as code snippets, and one-click suggestion blocks for mechanical fixes. Also resolves threads the skill posted in an earlier round once their findings are fixed. Use when the user asks to "add a draft review comment", "post review findings as separate comments", "leave inline review comments", "suggest a change on the diff", "resolve the review comments that are fixed", or wants reviewer findings turned into a pending PR review with deep links to the code.
---

# Draft Review Comments

Turn a set of review findings into a **PENDING (draft) GitHub PR review** composed of
**separate inline comments** anchored to lines in the diff. Each comment can open with an
AI-assisted disclosure and embed GitHub permalinks (deep links) that render as code snippets.

The review stays a draft (visible only to its author) until submitted, so the user can edit
or discard it on the PR page first.

## When to use

- "Add a draft review comment for these findings."
- "Make these separate review comments, not one top-level comment."
- "Link to the code with deep links so the snippet shows up."
- "Suggest the fix inline so I can commit it."
- After running the `review` skill, to publish the findings as a pending review.
- "Resolve the review comments that are now fixed" — a re-review round on a PR this skill
  already commented on. See [Re-review rounds](#re-review-rounds-resolve-threads-you-already-posted).

## Prerequisites

- `gh` authenticated (`gh auth status`). The authenticated user becomes the reviewer. A
  **pending COMMENT review on your own PR is allowed** (useful for self-review notes); you
  only cannot `APPROVE` / `REQUEST_CHANGES` your own PR.
- `jq` available (used to build the JSON body safely without escaping headaches).

## Ordering on a re-review

If the PR already has threads from an earlier round, **close out the old threads before
creating the new draft review**. Replying to a thread is blocked while you hold a pending
review (HTTP 422), so the sequence that works is:

1. Verify which earlier findings are fixed, reply on those threads, resolve them
   ([Re-review rounds](#re-review-rounds-resolve-threads-you-already-posted)).
2. Then build and post the new draft review (Steps 1-5).

Doing it the other way round leaves you unable to reply until you submit or delete the draft.

## Step 1 - Gather PR context

```bash
gh pr view --json number,title,url,baseRefName,headRefName,headRefOid
gh repo view --json nameWithOwner -q .nameWithOwner
```

Capture `number` (PR), `headRefOid` (the head SHA, used to pin permalinks AND as the review
`commit_id`), and `nameWithOwner` (`owner/repo`). For a stacked PR, `baseRefName` is the parent
branch; the change set for that PR is the diff between the base branch tip and `headRefOid`.

Pass `number` explicitly to the helper scripts below. From a git worktree, `gh pr view`
branch resolution can pick a different PR than the one you are reviewing.

Confirm your local checkout matches the PR head before computing anchors from local files:
`git rev-parse HEAD` must equal `headRefOid`. If they differ (unpushed commits, moved head),
line numbers read from disk will not match the diff GitHub sees and anchors will be dropped.

## Step 2 - Decide each finding's anchor

An inline review comment **must target a line that appears in the PR diff**. Inspect the hunks:

```bash
# For a normal PR: diff against the merge base with the base branch.
git diff "$(git merge-base origin/<baseRefName> HEAD)"..HEAD -- <path> | grep -n "^@@"
# For a single-commit stacked PR: just the top commit.
git diff HEAD~1..HEAD -- <path> | grep -n "^@@"
```

Anchoring rules:
- **Added lines** (`+` in the diff): `side: "RIGHT"`, use the **new-file** line number.
- **Removed / context lines**: `side: "LEFT"`, use the **old-file** line number.
- **Multi-line** comment: set both `start_line` and `line` (plus `side`); GitHub highlights the range.
- If the comment will carry a `suggestion` block, the anchor is no longer a readability
  choice: it must cover **exactly** the lines the suggestion replaces. See
  [Suggestion blocks](#suggestion-blocks).
- If a location you want to reference is **NOT in the diff** (e.g. unchanged code in another
  file), you cannot anchor an inline comment there. Reference it with a **deep-link permalink**
  inside the comment body instead (Step 3).

Verify the exact line numbers by reading the file at the head SHA before anchoring; off-by-one
anchors get rejected or land on the wrong line. Anchor to the distinctive code line (the
`def`, the statement, the `@@`-relative added line), not the blank line above it: a blank
added line is a valid anchor, so the comment silently lands one line off instead of erroring.

## Step 3 - Build deep-link permalinks

Pin every permalink to the head SHA so it never drifts. Put each link **on its own line with a
blank line around it** so GitHub renders it as an embedded code snippet:

```
https://github.com/<owner>/<repo>/blob/<headRefOid>/<path>#L<start>-L<end>
```

Helper:

```bash
./scripts/deeplink.sh <path> <start_line> [end_line] [pr_number]
```

## Step 4 - Write each comment body

Start every AI-assisted finding with this disclosure callout, verbatim. Do not reword it:

```markdown
> [!NOTE]
> Beep boop. AI-assisted review. Not my own words, but I reviewed and independently verified this finding.

**Finding: <short title>.**

<explanation>

<deep-link permalink for any code that is not the anchored line>

**Impact:** ...

**Suggested fix:** ...
```

Write each body to its own file (e.g. `/tmp/f1.md`, `/tmp/f2.md`) to avoid shell-escaping issues.

### Suggestion blocks

A `suggestion` block turns **Suggested fix** into a patch the author applies with one click,
and batches with other suggestions on the same PR. It **replaces the entire anchored range**
verbatim, so use one only when all three hold:

- The whole fix fits inside the anchored lines, on `side: "RIGHT"`.
- The fix is mechanical: you can write the exact replacement text, not just a direction.
- There is one obviously right fix. A suggestion forecloses the alternatives, so a
  design-level finding, or one with several defensible fixes, stays prose.

Otherwise keep the plain `**Suggested fix:**` prose. A bad suggestion costs more than a bad
prose comment: the author clicks **Commit suggestion** and your name is on the broken commit.

Write the replacement lines to their own unfenced file, carrying their real indentation, and
embed that same text in the body file under a `suggestion` fence:

````markdown
**Suggested fix:**

```suggestion
    if timeout is None:
        timeout = DEFAULT_TIMEOUT
```
````

Then check that it applies to something that still builds. Nothing in the API validates that
a suggestion applies cleanly, or even parses:

```bash
./scripts/check-suggestion.sh <path> <start_line> <end_line> /tmp/f1.suggestion
```

`check-suggestion.sh` splices the replacement lines into a copy of the file at the anchor
range, warns on a fence or indentation mismatch, and prints the diff plus the spliced file's
path. Run the project's formatter, typechecker, or tests against that path before posting.

## Step 5 - Post as a PENDING (draft) review

Build a **bare JSON array** of comment objects (one per finding) and post it. Omitting `event`
keeps the review **PENDING** (draft). Do **not** set a top-level `body` if the user wants only
separate inline comments.

`post-draft-review.sh` expects a bare array (it also tolerates a `{ comments: [...] }` wrapper),
so emit the array directly:

```bash
jq -n --rawfile b1 /tmp/f1.md --rawfile b2 /tmp/f2.md '[
  { path: "<path>", start_line: <s1>, line: <e1>, side: "RIGHT", body: $b1 },
  { path: "<path>", line: <e2>, side: "RIGHT", body: $b2 }
]' > /tmp/review.json

./scripts/post-draft-review.sh /tmp/review.json <pr_number>
```

`post-draft-review.sh` auto-fills `commit_id` (head SHA), repo, and PR number, POSTs the pending
review, prints its id/state/URL, and then compares the number of comments sent against the
number that landed. **The create-review response never reports dropped comments**, so this
sent-vs-landed check is the only signal that an anchor was rejected. If they differ, the script
prints how to inspect the anchors.

When you GET review comments back to verify, GitHub returns `line` / `side` / `start_line` as
`null` and stores the real anchor in `position` / `original_position`. Check `position`, not
`line` — a null `line` does **not** mean the anchor failed. Note that a sent-vs-landed match
confirms nothing was dropped, but a mismatch cannot distinguish a rejected anchor from a comment
a human deleted after posting; re-inspect the anchors either way.

## Re-review rounds: resolve threads you already posted

On a second pass over the same PR, threads from the earlier round whose findings are now fixed
should be resolved, so the PR shows only live findings. Do this **before** creating the new
draft review (see [Ordering on a re-review](#ordering-on-a-re-review)).

### 1. List the threads

```bash
./scripts/list-threads.sh <pr_number>
```

TAB-separated: `thread_id  comment_id  resolved  outdated  review_state  author  path  first_finding_line`.

`thread_id` (`PRRT_...`) is what resolving takes; `comment_id` (numeric) is what replying
takes. They are not interchangeable.

### 2. Decide what is genuinely fixed

Two traps here, both of which will quietly bury a live finding:

- **`outdated=true` is not evidence of a fix.** It only means the diff moved under the
  comment. A refactor that shuffles lines outdates every thread it touches while fixing none
  of them. Verify each finding against current code, and where the finding included a
  reproduction, re-run it and confirm the behavior changed.
- **Only resolve threads whose first comment is yours.** A human reviewer's thread is theirs
  to close, even if you believe the finding is addressed. `resolve-threads.sh` refuses
  non-viewer threads unless `--force`.
- **An applied suggestion is evidence, not proof.** Committing your suggestion produces a
  commit on exactly the anchored lines and outdates the thread, but the author may have
  edited it before committing, or applied it while the real defect sat elsewhere. Read the
  resulting code the same as for any other fix.

If a fix is partial, or the refactor moved the same defect somewhere else, do not resolve.
File it in the new round and cross-reference the old thread instead.

### 3. Reply with what fixed it, then resolve

A resolved thread collapses, so a bare resolve leaves no record of why. Reply first, naming
the fix and a permalink to it:

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<pr>/comments/<comment_id>/replies \
  -F body=@/tmp/reply1.md
```

Use `-F body=@<file>` rather than an inline string, for the same escaping reasons as the
comment bodies in Step 4.

Then resolve:

```bash
./scripts/resolve-threads.sh <thread_id> [thread_id...]
./scripts/resolve-threads.sh --dry-run --file /tmp/thread-ids.txt
```

`resolve-threads.sh` skips (rather than aborting the batch) any thread that is already
resolved, belongs to an unsubmitted PENDING review, is not yours, or cannot be looked up.
`--dry-run` reports the decision for each without changing anything; `--force` allows
non-viewer threads but never overrides the PENDING guard.

## Submitting or discarding the draft

- The user submits it from the PR page (**Finish your review**), or:
  ```bash
  gh api repos/<owner>/<repo>/pulls/<pr>/reviews/<review_id>/events -f event=COMMENT
  ```
  (`event` may be `COMMENT`, `APPROVE`, or `REQUEST_CHANGES`.)
- Delete a draft review:
  ```bash
  gh api -X DELETE repos/<owner>/<repo>/pulls/<pr>/reviews/<review_id>
  ```

## Gotchas

- **One pending review per user per PR.** If a draft already exists, delete it first or the new
  one collides. To replace a top-level comment with separate inline comments, delete the old
  pending review and create a fresh one with a `comments` array and no `body`.
- **A pending review blocks thread replies.** While you hold an unsubmitted draft review on a
  PR, replying to any thread on it fails with `422 Validation Failed - user_id can only have
  one pending review per pull request`. This hits both the REST reply endpoint and GraphQL
  `addPullRequestReviewThreadReply`. Resolving a thread is **not** blocked. So post replies
  before creating the draft, or after submitting/deleting it.
- **Your own pending comments look like unresolved threads.** Draft comments appear in
  GraphQL `reviewThreads` with `isResolved: false`, indistinguishable from live findings except
  by `comments.pullRequestReview.state == "PENDING"`. A blanket "resolve every unresolved
  thread" therefore buries the findings you just wrote. `resolve-threads.sh` refuses these
  unconditionally.
- **Resolving needs the GraphQL thread id, not a comment id.** `resolveReviewThread` takes the
  `PRRT_...` node id. The numeric id in a comment URL (`#discussion_r3723273429`) is the REST
  comment id, which the reply endpoint takes instead. `list-threads.sh` prints both.
- **Anchor must be in the diff.** Lines outside the PR's changed hunks cannot host an inline
  comment; use a deep-link permalink in the body instead. GitHub **silently drops** such a
  comment from an otherwise-valid review rather than erroring, so always verify the
  sent-vs-landed count (the script does this for you).
- **Permalinks must stand alone** (blank line before and after) to render as snippets.
- **A suggestion replaces the whole anchored range**, so the anchor has to be the fix's exact
  extent, and the replacement text has to match the file's indentation byte for byte (tabs
  vs spaces included). A block with no content deletes the range.
- **Suggestions are RIGHT-side only.** Deleted lines cannot carry one, and a multi-line anchor
  whose range includes deleted lines is unsupported, so any `side: "LEFT"` finding stays prose.
  A suggestion also cannot span files or hunks.
- **Only diff-anchored comments render suggestions.** In a top-level review body, or next to a
  permalink for out-of-diff code, a `suggestion` fence renders as a dead code block with no
  apply button. Those findings stay prose.
- **Wrap a suggestion in four backticks** (` ````suggestion `) when the replacement text itself
  contains a fence, or the block terminates early.
- **Own-PR reviews are fine as COMMENT.** You can post a pending review and submit it with
  `event=COMMENT` on your own PR; GitHub only refuses `APPROVE` / `REQUEST_CHANGES` on it.
