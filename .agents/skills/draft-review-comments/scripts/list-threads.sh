#!/usr/bin/env bash
# List a PR's review threads with the metadata needed to decide what to resolve.
#
# Usage: list-threads.sh [pr_number]
#
#   pr_number : optional; defaults to the PR for the current branch. Pass it
#               explicitly from a git worktree, where branch resolution can pick
#               the wrong PR.
#
# Prints one TAB-separated row per thread:
#   thread_id  comment_id  resolved  outdated  review_state  author  path  first_finding_line
#
# thread_id is the GraphQL node id (PRRT_...) that resolve-threads.sh needs.
# comment_id is the numeric REST id of the thread's first comment, which is what the
# reply endpoint takes. The two are not interchangeable.
#
# Two columns decide whether a thread is a candidate for resolving:
#   review_state=PENDING marks a comment in YOUR OWN unsubmitted draft review. Those
#     show up as unresolved threads, so a naive "resolve everything unresolved" would
#     bury the findings you just wrote.
#   outdated=true only means the diff moved under the comment. It is NOT evidence the
#     finding was fixed; verify against current code before resolving.
set -euo pipefail

pr="${1:-}"

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
owner="${repo%%/*}"
name="${repo##*/}"

if [[ -z "$pr" ]]; then
  pr=$(gh pr view --json number -q .number)
fi

query=$(mktemp)
trap 'rm -f "$query"' EXIT
cat > "$query" <<'GRAPHQL'
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          comments(first: 1) {
            nodes {
              databaseId
              author { login }
              pullRequestReview { state }
              body
            }
          }
        }
      }
    }
  }
}
GRAPHQL

gh api graphql -F query=@"$query" -F owner="$owner" -F repo="$name" -F number="$pr" --jq '
  .data.repository.pullRequest.reviewThreads.nodes[]
  | .comments.nodes[0] as $c
  | [ .id,
      ($c.databaseId | tostring),
      (if .isResolved then "resolved" else "UNRESOLVED" end),
      (if .isOutdated then "outdated" else "current" end),
      ($c.pullRequestReview.state // "-"),
      $c.author.login,
      .path,
      ( $c.body | split("\n") | map(select(startswith("**"))) | (.[0] // (($c.body | split("\n"))[0])) | .[0:72] )
    ] | @tsv'
