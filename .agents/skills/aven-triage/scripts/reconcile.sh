#!/usr/bin/env bash
# For each open aven task linked to GitHub, report whether the source still
# needs attention. Read-only. Output: TSV of ref, labels, suggestion, detail, url.
#
# Suggestions:
#   close   the source is resolved (merged, closed, review submitted, unassigned)
#   keep    the source is still open and waiting on you
#   check   a waiting task's PR merged; confirm a release includes it before closing
set -euo pipefail
WS=${AVEN_TRIAGE_WORKSPACE:-work}
here=$(dirname "$0")
me=$(gh api user -q .login)

"$here/tracked.sh" | while IFS=$'\t' read -r ref status labels url; do
  case $status in done | canceled) continue ;; esac
  case $url in
  https://github.com/*/pull/*)
    pr=$(gh pr view "$url" --json state,reviewRequests,author,isDraft,reviewDecision)
    state=$(jq -r .state <<<"$pr")
    if [ "$state" = MERGED ] && [[ $labels == *waiting* ]]; then
      printf '%s\t%s\tcheck\tPR merged, confirm it shipped\t%s\n' "$ref" "$labels" "$url"
    elif [ "$state" != OPEN ]; then
      printf '%s\t%s\tclose\tPR %s\t%s\n' "$ref" "$labels" "$(tr A-Z a-z <<<"$state")" "$url"
    elif [[ $labels == *waiting* ]]; then
      printf '%s\t%s\tkeep\tstill open\t%s\n' "$ref" "$labels" "$url"
    elif [[ $labels == *review* ]]; then
      if jq -e --arg me "$me" '.reviewRequests | any(.login == $me)' <<<"$pr" >/dev/null; then
        printf '%s\t%s\tkeep\treview still requested\t%s\n' "$ref" "$labels" "$url"
      else
        printf '%s\t%s\tclose\treview no longer requested\t%s\n' "$ref" "$labels" "$url"
      fi
    else
      printf '%s\t%s\tkeep\tPR open, %s\t%s\n' "$ref" "$labels" \
        "$(jq -r '.reviewDecision // "no decision" | ascii_downcase' <<<"$pr")" "$url"
    fi
    ;;
  https://github.com/*/issues/*)
    issue=$(gh issue view "$url" --json state,assignees)
    if [ "$(jq -r .state <<<"$issue")" != OPEN ]; then
      printf '%s\t%s\tclose\tissue closed\t%s\n' "$ref" "$labels" "$url"
    elif [[ $labels == *issue* ]] && ! jq -e --arg me "$me" '.assignees | any(.login == $me)' <<<"$issue" >/dev/null; then
      printf '%s\t%s\tclose\tno longer assigned\t%s\n' "$ref" "$labels" "$url"
    else
      printf '%s\t%s\tkeep\tissue open\t%s\n' "$ref" "$labels" "$url"
    fi
    ;;
  esac
done
