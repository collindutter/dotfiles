#!/usr/bin/env bash
# github-attn-popup — prefix+P popup: browse everything that needs your attention.
#   Enter    open the item in the browser
#   ctrl-y   copy the URL
#   ctrl-r   force-refresh
set -uo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
# fzf runs --preview via $SHELL; force a POSIX shell so it doesn't break under fish.
export SHELL=/bin/bash
export GHA_DATA="${GITHUB_ATTN_CACHE:-$HOME/.cache/github-attn}/data.json"

feed() {
  github-attn list --json 2>/dev/null | jq -r '
    def emoji: {"review":"👀","your_turn":"🔴","mergeable":"🟢","mention":"💬","waiting":"⚪"}[.] // "•";
    def rank:  {"review":0,"your_turn":1,"mergeable":2,"mention":3,"waiting":4}[.] // 9;
    sort_by(.category | rank)[]
    | [ (.category | emoji),
        (.repo + (if .number then " #\(.number)" else "" end) + "  " + .title
          + (if (.reason // "") != "" then "  (\(.reason))" else "" end)),
        (.url // "") ] | @tsv'
}

header=$'👀 review   🔴 your turn   🟢 mergeable   💬 mention   ⚪ waiting\nEnter: open in browser   ctrl-y: copy URL   ctrl-r: refresh'
preview='url=$(printf "%s" {} | cut -f3);
  jq -r --arg u "$url" '\''.[] | select(.url==$u)
    | "\(.repo) #\(.number // "-")\n\n\(.title)\n\ncategory \(.category)\nreason   \(.reason)\nchecks   \(.checks)\nreview   \(.review_decision // "-")\ndraft    \(.is_draft)\nupdated  \(.updated_at // "-")\n\n\(.url)"'\'' "$GHA_DATA" 2>/dev/null'

selection="$(
  feed | fzf --ansi --with-nth=1,2 --delimiter='\t' \
    --header="$header" --header-first --prompt='attention > ' \
    --preview="$preview" --preview-window='right,45%,wrap' \
    --expect=ctrl-y,ctrl-r
)" || exit 0

key="$(head -1 <<<"$selection")"
row="$(sed -n '2p' <<<"$selection")"
[ -z "$row" ] && exit 0
IFS=$'\t' read -r _emoji _label url <<<"$row"

case "$key" in
  ctrl-r) github-attn poll >/dev/null 2>&1; exec "$0" ;;
  ctrl-y) printf '%s' "$url" | pbcopy ;;
  *) [ -n "$url" ] && open "$url" ;;
esac
