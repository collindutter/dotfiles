#!/usr/bin/env bash
# github-attn-popup — prefix+P: worktree-aware GitHub attention + prunable worktrees.
#
# Joins github-attn items to the local worktree index (by repo + PR number) so
# anything you have checked out can jump straight to its tmux window. Merged /
# closed worktrees show as prunable and can be removed here too.
#
#   Enter    jump to the worktree's tmux window if checked out, else open the PR
#   ctrl-b   open the PR in the browser
#   ctrl-x   remove the worktree (workmux rm), after a confirm
#   ctrl-y   copy the worktree path (or the URL)
#   ctrl-r   refresh both github-attn and the worktree index
set -uo pipefail

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
# fzf runs --preview via $SHELL; force a POSIX shell so it doesn't break under fish.
export SHELL=/bin/bash

PRUNE_POLL="$HOME/.local/bin/worktree-prune-poll"
WT_DATA="${WORKTREE_PRUNE_CACHE:-$HOME/.cache/worktree-prune}/data.json"
[ -f "$WT_DATA" ] || "$PRUNE_POLL" >/dev/null 2>&1
if [ ! -f "$WT_DATA" ]; then
  WT_DATA="$(mktemp)"
  echo '[]' >"$WT_DATA"
fi

# Live map of worktree path -> "session:window" so we can offer a jump.
panes_json="$(
  tmux list-panes -a -F '#{pane_current_path}	#{session_name}:#{window_index}' 2>/dev/null \
    | jq -R -s 'split("\n") | map(select(length > 0) | split("\t") | {(.[0]): .[1]}) | add // {}'
)"
[ -z "$panes_json" ] && panes_json='{}'

# Row columns: marker \t label \t url \t wt_path \t repo_path \t handle \t loc
feed() {
  # Attention items from github-attn, annotated with their local worktree window.
  github-attn list --json 2>/dev/null | jq -r \
    --argjson panes "$panes_json" \
    --slurpfile wt "$WT_DATA" '
      def emoji: {"review":"👀","your_turn":"🔴","mergeable":"🟢","mention":"💬","waiting":"⚪"}[.] // "•";
      def rank:  {"review":0,"your_turn":1,"mergeable":2,"mention":3,"waiting":4}[.] // 9;
      (($wt[0] // []) | map({key: (.slug + "#" + ((.number // 0) | tostring)), value: .}) | from_entries) as $wtmap
      | sort_by(.category | rank)[]
      | ($wtmap[.repo + "#" + ((.number // 0) | tostring)]) as $w
      | (($w.path) // "") as $path
      | ($panes[$path] // "") as $loc
      | [ (.category | emoji),
          (.repo + (if .number then " #\(.number)" else "" end) + "  " + .title
            + (if (.reason // "") != "" then "  (" + .reason + ")" else "" end)
            + (if $loc != "" then "  → " + $loc else "" end)),
          (.url // ""), $path, (($w.repo_path) // ""), (($w.handle) // ""), $loc ] | @tsv'
  # Prunable worktrees (merged/closed PRs are not attention items, so add them).
  jq -r --argjson panes "$panes_json" '
    .[] | select(.prunable)
    | (.path // "") as $path
    | ($panes[$path] // "") as $loc
    | [ "🧹",
        (.repo + "/" + .handle + "  #\(.number)  " + (.title // "")
          + "  (" + (.state | ascii_downcase) + ")"
          + (if $loc != "" then "  → " + $loc else "" end)),
        (.url // ""), $path, (.repo_path // ""), (.handle // ""), $loc ] | @tsv' "$WT_DATA"
}

header=$'👀 review  🔴 your turn  🟢 mergeable  💬 mention  ⚪ waiting  🧹 prunable\nEnter: jump to worktree / open PR   ctrl-b: open PR   ctrl-x: remove worktree   ctrl-y: copy   ctrl-r: refresh'
preview='printf "%s\n" {} | awk -F"\t" "{ print \$2; print \"\"; if (\$7 != \"\") print \"window:   \" \$7; if (\$4 != \"\") print \"worktree: \" \$4; if (\$3 != \"\") print \$3 }"'

selection="$(
  feed | fzf --ansi --with-nth=1,2 --delimiter='\t' \
    --header="$header" --header-first --prompt='attention > ' \
    --preview="$preview" --preview-window='down,30%,wrap' \
    --expect=ctrl-b,ctrl-x,ctrl-y,ctrl-r
)" || exit 0

key="$(head -1 <<<"$selection")"
row="$(sed -n '2p' <<<"$selection")"
[ -z "$row" ] && exit 0
IFS=$'\t' read -r _marker _label url wt_path repo_path handle loc <<<"$row"

case "$key" in
  ctrl-r)
    github-attn poll >/dev/null 2>&1 &
    "$PRUNE_POLL" >/dev/null 2>&1
    wait
    exec "$0"
    ;;
  ctrl-y)
    if [ -n "$wt_path" ]; then
      printf '%s' "$wt_path" | pbcopy
    elif [ -n "$url" ]; then
      printf '%s' "$url" | pbcopy
    fi
    ;;
  ctrl-b)
    [ -n "$url" ] && open "$url"
    ;;
  ctrl-x)
    if [ -n "$repo_path" ] && [ -n "$handle" ]; then
      printf 'Remove worktree %s/%s? [y/N] ' "$(basename "$repo_path")" "$handle"
      read -r reply
      if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
        ( cd "$repo_path" && workmux remove -f "$handle" ) 2>&1 | tail -3
        "$PRUNE_POLL" >/dev/null 2>&1
        exec "$0"
      fi
    fi
    ;;
  *)
    if [ -n "$loc" ]; then
      tmux switch-client -t "$loc"
    elif [ -n "$url" ]; then
      open "$url"
    fi
    ;;
esac
