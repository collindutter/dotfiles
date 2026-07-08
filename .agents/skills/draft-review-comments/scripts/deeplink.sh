#!/usr/bin/env bash
# Print a GitHub permalink pinned to the PR head SHA for a path + line range.
# Each link, placed on its own line in a comment body, renders as a code snippet.
#
# Usage: deeplink.sh <path> <start_line> [end_line] [pr_number]
set -euo pipefail

path="${1:?usage: deeplink.sh <path> <start_line> [end_line] [pr_number]}"
start="${2:?need a start line}"
end="${3:-}"
pr="${4:-}"

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
if [[ -z "$pr" ]]; then
  sha=$(gh pr view --json headRefOid -q .headRefOid)
else
  sha=$(gh pr view "$pr" --json headRefOid -q .headRefOid)
fi

url="https://github.com/$repo/blob/$sha/$path#L$start"
if [[ -n "$end" ]]; then
  url="${url}-L${end}"
fi
echo "$url"
