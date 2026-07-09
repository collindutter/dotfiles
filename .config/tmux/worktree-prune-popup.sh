#!/usr/bin/env bash
# worktree-prune-popup — prefix+X popup: review worktrees whose PR has landed
# and remove them.
#   Enter    remove the worktree (workmux rm), after a confirm
#   ctrl-o   jump to the worktree's tmux window (if open)
#   ctrl-b   open the PR in the browser
#   ctrl-y   copy the worktree path
#   ctrl-r   force-refresh
set -uo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
# fzf runs --preview via $SHELL; force a POSIX shell so it doesn't break under fish.
export SHELL=/bin/bash
CACHE="${WORKTREE_PRUNE_CACHE:-$HOME/.cache/worktree-prune}"
export WTP_DATA="$CACHE/data.json"
POLLER="$HOME/.local/bin/worktree-prune-poll"

[ -f "$WTP_DATA" ] || "$POLLER" >/dev/null 2>&1

count="$(jq 'length' "$WTP_DATA" 2>/dev/null || echo 0)"
if [ "${count:-0}" -eq 0 ]; then
  echo "Nothing to prune — no worktrees with a merged/closed PR. 🧹"
  read -rn 1 -p "Press any key to close…"
  exit 0
fi

# Live map of worktree path -> "session:window" so we can offer a jump.
panes="$(tmux list-panes -a -F '#{pane_current_path}	#{session_name}:#{window_index}' 2>/dev/null || true)"
loc_for() { awk -F'\t' -v p="$1" '$1==p {print $2; exit}' <<<"$panes"; }

feed() {
  jq -r '
    def mark: if . == "MERGED" then "merged" else "closed" end;
    sort_by(.repo, .handle)[]
    | [ (.state | mark),
        (.repo + "/" + .handle + "  #\(.number)  " + (.title // "")),
        .path, .repo_path, .handle, (.url // "") ] | @tsv
  ' "$WTP_DATA"
}

header=$'worktrees whose PR has landed — safe to remove\nEnter: remove (workmux rm)   ctrl-o: jump   ctrl-b: open PR   ctrl-y: copy path   ctrl-r: refresh'
preview='path=$(printf "%s" {} | cut -f3);
  jq -r --arg p "$path" '\''.[] | select(.path==$p)
    | "\(.repo)/\(.handle)\n\nPR      #\(.number)  \(.title)\nstate   \(.state)\nbranch  \(.branch)\npath    \(.path)\n\n\(.url)"'\'' "$WTP_DATA" 2>/dev/null'

selection="$(
  feed | fzf --ansi --with-nth=1,2 --delimiter='\t' \
    --header="$header" --header-first --prompt='prune > ' \
    --preview="$preview" --preview-window='down,40%,wrap' \
    --expect=ctrl-o,ctrl-b,ctrl-y,ctrl-r
)" || exit 0

key="$(head -1 <<<"$selection")"
row="$(sed -n '2p' <<<"$selection")"
[ -z "$row" ] && exit 0
IFS=$'\t' read -r _mark _label path repo_path handle url <<<"$row"

case "$key" in
  ctrl-r)
    "$POLLER" >/dev/null 2>&1
    exec "$0"
    ;;
  ctrl-y)
    printf '%s' "$path" | pbcopy
    ;;
  ctrl-b)
    [ -n "$url" ] && open "$url"
    ;;
  ctrl-o)
    loc="$(loc_for "$path")"
    if [ -n "$loc" ]; then
      tmux switch-client -t "$loc"
    elif [ -n "$repo_path" ] && [ -n "$handle" ]; then
      ( cd "$repo_path" && workmux open "$handle" ) >/dev/null 2>&1
    fi
    ;;
  *)
    # Enter: remove the worktree after confirming.
    printf 'Remove worktree %s/%s? [y/N] ' "$(basename "$repo_path")" "$handle"
    read -r reply
    if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
      ( cd "$repo_path" && workmux remove -f "$handle" ) 2>&1 | tail -3
      "$POLLER" >/dev/null 2>&1
      exec "$0"
    fi
    ;;
esac
