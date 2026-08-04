#!/usr/bin/env bash
# Fuzzy window switcher across all tmux sessions, bound to `prefix W`.
#
#   Enter   switch to the selected window

set -euo pipefail

current=$(tmux display-message -p '#{session_name}:#{window_index}')

selection=$(
  tmux list-windows -a -F '#{session_name}:#{window_index}|#{session_name}  #{window_name}#{?window_active_clients,  ●,}' |
    grep -v "^$current|" | fzf \
      --ansi --tiebreak=length,begin,index \
      --delimiter '|' --with-nth 2 \
      --header '  enter switch' \
      --bind 'tab:down,btab:up'
) || exit 0

[ -z "$selection" ] && exit 0

target=${selection%%|*}
tmux switch-client -t "$target"
