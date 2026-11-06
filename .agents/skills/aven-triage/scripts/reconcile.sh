#!/usr/bin/env bash
# For each open aven task linked to GitHub, report whether the source still
# needs attention. Read-only. Output: TSV of ref, labels, suggestion, detail, url.
#
# Suggestions:
#   close   the source is resolved (merged, closed, review submitted, unassigned)
#   keep    the source is still open and waiting on you
#   check   a waiting task's PR merged; confirm a release includes it before closing
#   re-review  an awaiting-author PR has a re-request or commits since your review
#   awaiting-review  your PR has no human review since its last commit; add the label
#   act     an awaiting-review PR has a decision or a human review since its last commit
set -euo pipefail
WS=${AVEN_TRIAGE_WORKSPACE:-work}
here=$(dirname "$0")
me=$(gh api user -q .login)

has() { [[ ,$labels, == *,$1,* ]]; }

# Human reviews (not you, not bots) submitted after the PR's latest commit.
fresh_reviews='([.commits[].committedDate] | max) as $last
  | [.reviews[] | select(.author.login != $me and .author.login != "griptapeops"
      and (.author.login | endswith("[bot]") | not) and .submittedAt > $last)] | length'

"$here/tracked.sh" | while IFS=$'\t' read -r ref status labels url; do
  case $status in done | canceled) continue ;; esac
  case $url in
  https://github.com/*/pull/*)
    pr=$(gh pr view "$url" --json state,reviewRequests,author,isDraft,reviewDecision,reviews,commits)
    state=$(jq -r .state <<<"$pr")
    if [ "$state" = MERGED ] && has waiting; then
      printf '%s\t%s\tcheck\tPR merged, confirm it shipped\t%s\n' "$ref" "$labels" "$url"
    elif [ "$state" != OPEN ]; then
      printf '%s\t%s\tclose\tPR %s\t%s\n' "$ref" "$labels" "$(tr A-Z a-z <<<"$state")" "$url"
    elif has waiting; then
      printf '%s\t%s\tkeep\tstill open\t%s\n' "$ref" "$labels" "$url"
    elif has awaiting-author; then
      if jq -e --arg me "$me" '.reviewRequests | any(.login == $me)' <<<"$pr" >/dev/null; then
        printf '%s\t%s\tre-review\treview re-requested\t%s\n' "$ref" "$labels" "$url"
      elif jq -e --arg me "$me" '
        ([.reviews[] | select(.author.login == $me) | .submittedAt] | max) as $last
        | $last != null and ([.commits[].committedDate] | max) > $last' <<<"$pr" >/dev/null; then
        printf '%s\t%s\tre-review\tcommits since your review\t%s\n' "$ref" "$labels" "$url"
      else
        printf '%s\t%s\tkeep\tawaiting author\t%s\n' "$ref" "$labels" "$url"
      fi
    elif has review; then
      if jq -e --arg me "$me" '.reviewRequests | any(.login == $me)' <<<"$pr" >/dev/null; then
        printf '%s\t%s\tkeep\treview still requested\t%s\n' "$ref" "$labels" "$url"
      else
        printf '%s\t%s\tclose\treview no longer requested\t%s\n' "$ref" "$labels" "$url"
      fi
    elif has my-pr; then
      decision=$(jq -r '.reviewDecision // "" | ascii_downcase' <<<"$pr")
      fresh=$(jq --arg me "$me" "$fresh_reviews" <<<"$pr")
      if [ "$decision" = approved ] || [ "$decision" = changes_requested ]; then
        verdict=act detail="PR ${decision/_/ }"
      elif [ "$fresh" -gt 0 ]; then
        verdict=act detail="$fresh review(s) since last commit"
      else
        verdict=awaiting-review detail="awaiting review"
      fi
      if has awaiting-review; then
        [ "$verdict" = act ] || verdict=keep
      elif [ "$verdict" = act ]; then
        verdict=keep
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' "$ref" "$labels" "$verdict" "$detail" "$url"
    else
      printf '%s\t%s\tkeep\tPR open, %s\t%s\n' "$ref" "$labels" \
        "$(jq -r '.reviewDecision // "no decision" | ascii_downcase' <<<"$pr")" "$url"
    fi
    ;;
  https://github.com/*/issues/*)
    issue=$(gh issue view "$url" --json state,assignees)
    if [ "$(jq -r .state <<<"$issue")" != OPEN ]; then
      printf '%s\t%s\tclose\tissue closed\t%s\n' "$ref" "$labels" "$url"
    elif has issue && ! jq -e --arg me "$me" '.assignees | any(.login == $me)' <<<"$issue" >/dev/null; then
      printf '%s\t%s\tclose\tno longer assigned\t%s\n' "$ref" "$labels" "$url"
    else
      printf '%s\t%s\tkeep\tissue open\t%s\n' "$ref" "$labels" "$url"
    fi
    ;;
  esac
done
