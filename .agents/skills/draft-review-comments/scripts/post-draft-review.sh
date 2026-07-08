#!/usr/bin/env bash
# Post a PENDING (draft) PR review built from a comments JSON file.
#
# Usage: post-draft-review.sh <comments.json> [pr_number]
#
#   comments.json : the review comments, in either shape:
#                   - a bare JSON ARRAY of review-comment objects, e.g.
#                     [ { "path": "src/x.py", "line": 42, "side": "RIGHT", "body": "..." },
#                       { "path": "src/x.py", "start_line": 10, "line": 20,
#                         "side": "RIGHT", "body": "..." } ]
#                   - OR a { "comments": [ ... ] } wrapper around that array.
#                   Both are accepted, so it does not matter which shape jq produced.
#   pr_number     : optional; defaults to the PR for the current branch. Pass it
#                   explicitly from a git worktree, where branch resolution can pick
#                   the wrong PR.
#
# The script fills in commit_id (PR head SHA), repo, and PR number automatically,
# then creates a PENDING (draft) review (no top-level body, no `event`). After
# posting it compares the number of comments sent against the number that landed:
# GitHub silently drops any comment whose anchor is not on a line in the diff and
# never reports this in the create response.
set -euo pipefail

comments_file="${1:?usage: post-draft-review.sh <comments.json> [pr_number]}"
pr="${2:-}"

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)

if [[ -z "$pr" ]]; then
  pr=$(gh pr view --json number -q .number)
  sha=$(gh pr view --json headRefOid -q .headRefOid)
else
  sha=$(gh pr view "$pr" --json headRefOid -q .headRefOid)
fi

payload=$(mktemp)
trap 'rm -f "$payload"' EXIT
# Accept either a bare array of comment objects or a {comments:[...]} wrapper.
jq -n --arg sha "$sha" --slurpfile c "$comments_file" \
  '{commit_id: $sha,
    comments: (if ($c[0] | type) == "array" then $c[0] else $c[0].comments end)}' > "$payload"

sent=$(jq '.comments | length' "$payload")

response=$(gh api "repos/$repo/pulls/$pr/reviews" -X POST --input "$payload")
review_id=$(jq -r '.id' <<<"$response")
jq '{id, state, html_url}' <<<"$response"

# Compare sent vs landed. A mismatch means GitHub rejected an anchor outside the diff.
landed=$(gh api "repos/$repo/pulls/$pr/reviews/$review_id/comments" --jq 'length')
echo
if [[ "$sent" == "$landed" ]]; then
  echo "All $sent comment(s) anchored and landed on $repo #$pr (state PENDING)."
else
  echo "WARNING: sent $sent comment(s) but only $landed landed on $repo #$pr."
  echo "GitHub dropped $((sent - landed)) whose anchor is not on a line in the diff."
  echo "Inspect anchors with (verify against 'position'/'original_position', not 'line'):"
  echo "  gh api repos/$repo/pulls/$pr/reviews/$review_id/comments --jq '.[] | {path, position, original_position}'"
fi
echo
echo "Submit it from the PR page, or:"
echo "  gh api repos/$repo/pulls/$pr/reviews/$review_id/events -f event=COMMENT"
echo "Delete it with:"
echo "  gh api -X DELETE repos/$repo/pulls/$pr/reviews/$review_id"
