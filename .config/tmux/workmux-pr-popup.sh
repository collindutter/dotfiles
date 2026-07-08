#!/usr/bin/env bash
# workmux-pr-popup — prefix+P popup: browse every workmux worktree PR and see
# which tmux session/window it lives in.
#   Enter    jump to the worktree's tmux window (or `workmux open` if closed)
#   ctrl-b   open the PR in the browser
#   ctrl-y   copy the worktree path to the clipboard
#   ctrl-r   force-refresh the cache
set -uo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
# fzf runs --preview via $SHELL; force a POSIX shell so the preview (written in
# sh syntax) doesn't break under fish.
export SHELL=/bin/bash

HELPER="$HOME/.local/bin/workmux-pr"
export WMPR_DATA="${WORKMUX_PR_CACHE:-$HOME/.cache/workmux-pr}/data.json"

header=$'👀 review you   🔴 your turn   🟢 mergeable   🟣 prunable   ⚪ waiting   ⚫ no PR\nEnter: jump to window   ctrl-b: open PR   ctrl-y: copy path   ctrl-r: refresh'

# Preview shows the highlighted worktree's PR detail, keyed on the URL column.
preview='url=$(printf "%s" {} | cut -f3);
  if [ -z "$url" ]; then
    printf "%s\n\nno associated PR" "$(printf "%s" {} | cut -f2)";
  else
    jq -r --arg u "$url" '\''.[] | select(.url==$u)
      | "\(.repo)/\(.handle)\n\nPR      #\(.number)  \(.title)\nbranch  \(.branch)\nstate   \(.state)\nreview  \(.reviewDecision // "-")\nchecks  \(.checks)\nauthor  \(.author // "-")\ndraft   \(.isDraft)\nupdated \(.updatedAt // "-")\n\n\(.url)"'\'' "$WMPR_DATA";
  fi'

selection="$(
  "$HELPER" --fzf | fzf \
    --ansi --with-nth=1,2 --delimiter='\t' \
    --header="$header" \
    --header-first \
    --prompt='worktree PRs > ' \
    --preview="$preview" \
    --preview-window='right,45%,wrap' \
    --expect=ctrl-b,ctrl-y,ctrl-r
)" || exit 0

key="$(head -1 <<<"$selection")"
row="$(sed -n '2p' <<<"$selection")"
[ -z "$row" ] && exit 0

IFS=$'\t' read -r _emoji _label url path repo_path handle session window <<<"$row"

case "$key" in
  ctrl-r)
    "$HELPER" --refresh >/dev/null 2>&1
    exec "$0"
    ;;
  ctrl-y)
    printf '%s' "$path" | pbcopy
    ;;
  ctrl-b)
    [ -n "$url" ] && open "$url"
    ;;
  *)
    # Enter: jump to the live tmux window, else open one via workmux.
    if [ -n "$session" ] && [ -n "$window" ]; then
      tmux switch-client -t "${session}:${window}"
    elif [ -n "$repo_path" ] && [ -n "$handle" ]; then
      ( cd "$repo_path" && workmux open "$handle" ) >/dev/null 2>&1
    fi
    ;;
esac
