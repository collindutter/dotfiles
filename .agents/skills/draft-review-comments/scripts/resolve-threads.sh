#!/usr/bin/env bash
# Resolve review threads that this skill posted and whose findings are now fixed.
#
# Usage: resolve-threads.sh [--dry-run] [--force] <thread_id> [thread_id...]
#        resolve-threads.sh [--dry-run] [--force] --file <ids.txt>
#
#   thread_id : GraphQL node id (PRRT_...) from list-threads.sh. NOT a REST comment id.
#   --file    : read thread ids from a file, one per line (blank lines and # ignored).
#   --dry-run : report what each thread would do, change nothing.
#   --force   : resolve even when the thread's first comment is not yours. Off by
#               default so a human reviewer's thread is never resolved on their behalf.
#
# Refuses, always, to resolve a thread whose first comment belongs to a PENDING review:
# that is an unsubmitted draft comment (very likely one you just wrote), and resolving it
# would collapse a finding before anyone read it. --force does not override this.
#
# Resolving is NOT blocked by having a pending review open, but posting a reply to a
# thread IS (HTTP 422, "user_id can only have one pending review per pull request"). So
# if you want an explanatory reply on each thread, post the replies BEFORE creating the
# new draft review, or after submitting/deleting it. See SKILL.md.
set -euo pipefail

dry_run=false
force=false
ids=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    --force)   force=true; shift ;;
    --file)
      file="${2:?--file needs a path}"
      while IFS= read -r line; do
        line="${line%%#*}"
        line="$(tr -d '[:space:]' <<<"$line")"
        [[ -n "$line" ]] && ids+=("$line")
      done < "$file"
      shift 2 ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *)  ids+=("$1"); shift ;;
  esac
done

if [[ ${#ids[@]} -eq 0 ]]; then
  echo "usage: resolve-threads.sh [--dry-run] [--force] <thread_id>... | --file <ids.txt>" >&2
  exit 2
fi

inspect=$(mktemp)
resolve=$(mktemp)
trap 'rm -f "$inspect" "$resolve"' EXIT

cat > "$inspect" <<'GRAPHQL'
query($tid: ID!) {
  viewer { login }
  node(id: $tid) {
    ... on PullRequestReviewThread {
      id
      isResolved
      path
      comments(first: 1) {
        nodes {
          author { login }
          pullRequestReview { state }
        }
      }
    }
  }
}
GRAPHQL

cat > "$resolve" <<'GRAPHQL'
mutation($tid: ID!) {
  resolveReviewThread(input: {threadId: $tid}) {
    thread { id isResolved }
  }
}
GRAPHQL

resolved_count=0
skipped_count=0

for tid in "${ids[@]}"; do
  # A malformed or unknown id makes `gh` exit non-zero; skip it rather than aborting
  # the whole batch under `set -e`.
  if ! info=$(gh api graphql -F query=@"$inspect" -F tid="$tid" 2>&1); then
    echo "SKIP  $tid  could not be looked up: $(tr '\n' ' ' <<<"$info" | cut -c1-100)"
    skipped_count=$((skipped_count + 1))
    continue
  fi

  viewer=$(jq -r '.data.viewer.login' <<<"$info")
  thread_id=$(jq -r '.data.node.id // empty' <<<"$info")
  already=$(jq -r '.data.node.isResolved' <<<"$info")
  path=$(jq -r '.data.node.path // "-"' <<<"$info")
  author=$(jq -r '.data.node.comments.nodes[0].author.login // "-"' <<<"$info")
  state=$(jq -r '.data.node.comments.nodes[0].pullRequestReview.state // "-"' <<<"$info")

  if [[ -z "$thread_id" ]]; then
    echo "SKIP  $tid  not a review thread (check you used the PRRT_ node id, not a comment id)"
    skipped_count=$((skipped_count + 1))
    continue
  fi
  if [[ "$already" == "true" ]]; then
    echo "SKIP  $tid  already resolved  ($path)"
    skipped_count=$((skipped_count + 1))
    continue
  fi
  if [[ "$state" == "PENDING" ]]; then
    echo "SKIP  $tid  belongs to an unsubmitted PENDING review  ($path)"
    skipped_count=$((skipped_count + 1))
    continue
  fi
  if [[ "$author" != "$viewer" && "$force" != true ]]; then
    echo "SKIP  $tid  first comment is by '$author', not you ('$viewer'); pass --force to override  ($path)"
    skipped_count=$((skipped_count + 1))
    continue
  fi
  if [[ "$dry_run" == true ]]; then
    echo "WOULD RESOLVE  $tid  ($path)"
    continue
  fi

  out=$(gh api graphql -F query=@"$resolve" -F tid="$tid" --jq '.data.resolveReviewThread.thread.isResolved')
  echo "RESOLVED  $tid  isResolved=$out  ($path)"
  resolved_count=$((resolved_count + 1))
done

echo
if [[ "$dry_run" == true ]]; then
  echo "Dry run: nothing changed. $skipped_count skipped."
else
  echo "Resolved $resolved_count thread(s), skipped $skipped_count."
fi
