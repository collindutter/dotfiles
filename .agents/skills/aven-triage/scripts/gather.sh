#!/usr/bin/env bash
# List GitHub items that may need attention, are not tracked in aven, and are
# not in the ignore list ($AVEN_TRIAGE_IGNORE, one URL per line).
# Read-only. Output: JSON array of {kind, url, repo, title, updated, draft, base, head}.
#
# kind is one of: review, my-pr, issue, mention.
# Assigned issues untouched for STALE_DAYS (default 60) are left out; the count
# is printed to stderr so the agent can mention it.
set -euo pipefail
here=$(dirname "$0")
STALE_DAYS=${STALE_DAYS:-60}
MENTION_DAYS=${MENTION_DAYS:-14}
cutoff=$(date -v-"${STALE_DAYS}"d +%F)
fields=url,title,repository,updatedAt
ignore=${AVEN_TRIAGE_IGNORE:-$HOME/.local/state/aven-triage/ignored.txt}

tracked=$(mktemp)
trap 'rm -f "$tracked"' EXIT
{
  "$here/tracked.sh" | cut -f4
  if [ -f "$ignore" ]; then cut -d" " -f1 "$ignore"; fi
} | jq -R . | jq -s . >"$tracked"

norm='map({url, title, repo: .repository.nameWithOwner, updated: .updatedAt[:10], draft: (.isDraft // false)})'

reviews=$(gh search prs --review-requested=@me --state=open --archived=false --json $fields,isDraft --limit 50 |
  jq "$norm | map(. + {kind: \"review\"})")
mine=$(gh search prs --author=@me --state=open --archived=false --json $fields,isDraft --limit 50 |
  jq "$norm | map(. + {kind: \"my-pr\"})")
issues=$(gh search issues --assignee=@me --state=open --archived=false --json $fields --limit 100 |
  jq "$norm | map(. + {kind: \"issue\"})")
mentions=$(gh search issues --mentions=@me --state=open --archived=false --updated=">$(date -v-"${MENTION_DAYS}"d +%F)" \
  --json $fields --limit 50 | jq "$norm | map(. + {kind: \"mention\"})")

stale=$(jq --arg c "$cutoff" '[.[] | select(.updated < $c)] | length' <<<"$issues")
echo "skipped $stale assigned issues not updated since $cutoff" >&2

# Add base and head branches to your PRs so stacks can be ordered by branch, not number.
mine=$(jq -c '.[]' <<<"$mine" | while read -r pr; do
  url=$(jq -r .url <<<"$pr")
  gh pr view "$url" --json baseRefName,headRefName |
    jq -c --argjson pr "$pr" '$pr + {base: .baseRefName, head: .headRefName}'
done | jq -s .)

jq -n --slurpfile t "$tracked" --arg c "$cutoff" \
  --argjson r "$reviews" --argjson m "$mine" --argjson i "$issues" --argjson n "$mentions" '
  ($t[0]) as $tracked
  | ($r + $m + [$i[] | select(.updated >= $c)] + $n)
  | unique_by(.url)
  | map(select(.url as $u | $tracked | index($u) | not))'
