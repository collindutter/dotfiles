---
name: pr-review-comments
description: Get all unresolved PR review comments for the current branch.
allowed-tools: Bash(gh *)
---

# Get Unresolved PR Review Comments

Get all unresolved PR review comments for the current branch.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 100) {
            nodes {
              author { login }
              path
              line
              originalLine
              body
              url
            }
          }
        }
      }
    }
  }
}
' -F owner=$(gh repo view --json owner -q .owner.login) -F repo=$(gh repo view --json name -q .name) -F number=$(gh pr view --json number -q .number) --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .comments.nodes[] | "[\(.author.login)] \(.path):\(.line // .originalLine)\n\(.body)\n\(.url)\n---"'
```
