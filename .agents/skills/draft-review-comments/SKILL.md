---
name: draft-review-comments
description: Post a DRAFT (pending) GitHub PR review made of separate inline review comments anchored to the diff, each with an AI-assisted disclosure and GitHub deep-link permalinks that render as code snippets. Use when the user asks to "add a draft review comment", "post review findings as separate comments", "leave inline review comments", or wants reviewer findings turned into a pending PR review with deep links to the code.
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
- After running the `review` skill, to publish the findings as a pending review.

## Prerequisites

- `gh` authenticated (`gh auth status`). The authenticated user becomes the reviewer. A
  **pending COMMENT review on your own PR is allowed** (useful for self-review notes); you
  only cannot `APPROVE` / `REQUEST_CHANGES` your own PR.
- `jq` available (used to build the JSON body safely without escaping headaches).

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
> AI-assisted review. Not my own words, but I reviewed and independently verified this finding.

**Finding: <short title>.**

<explanation>

<deep-link permalink for any code that is not the anchored line>

**Impact:** ...

**Suggested fix:** ...
```

Write each body to its own file (e.g. `/tmp/f1.md`, `/tmp/f2.md`) to avoid shell-escaping issues.

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
- **Anchor must be in the diff.** Lines outside the PR's changed hunks cannot host an inline
  comment; use a deep-link permalink in the body instead. GitHub **silently drops** such a
  comment from an otherwise-valid review rather than erroring, so always verify the
  sent-vs-landed count (the script does this for you).
- **Permalinks must stand alone** (blank line before and after) to render as snippets.
- **Own-PR reviews are fine as COMMENT.** You can post a pending review and submit it with
  `event=COMMENT` on your own PR; GitHub only refuses `APPROVE` / `REQUEST_CHANGES` on it.
