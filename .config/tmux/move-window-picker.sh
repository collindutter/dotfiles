#!/usr/bin/env bash
# Move the current tmux window into another session, picked with sesh.
# This is tmux's `prefix .` (move-window) flow, but with sesh's fuzzy picker,
# and it can also create a brand-new session on the fly from a zoxide dir,
# a config, or a found directory.
#
#   Enter   move the current window into the selected session
#   C-s     move the window, then switch to that session
#
# Note: creating a session from a sesh config here uses a plain detached
# session at the config's path; the config's startup commands are not run.

set -euo pipefail

result=$(
  sesh list --icons -H | fzf \
    --ansi --tiebreak=length,begin,index \
    --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^f find    enter move  ^s move+switch' \
    --expect=ctrl-s \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons -H)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons -H)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)'
) || exit 0

key=$(printf '%s\n' "$result" | sed -n '1p')
selection=$(printf '%s\n' "$result" | sed -n '2p')

[ -z "$selection" ] && exit 0

# Strip any ANSI color codes that survive fzf --ansi output.
clean=$(printf '%s' "$selection" | sed -E $'s/\x1b\\[[0-9;]*m//g')

case "$clean" in
  /*)
    # Find-mode entries are bare absolute paths.
    path=$clean
    # tmux disallows '.' and ':' in session names; mirror how sesh sanitizes.
    name=$(basename "$path" | tr '.:' '__')
    ;;
  *)
    # Sesh-mode entries are "<icon> <name>". Strip the icon glyph and
    # whitespace, then look the name up in the sesh JSON to get the path.
    name=$(printf '%s' "$clean" | sed -E 's/^[^[:space:]]+[[:space:]]+//')
    path=$(sesh list -H --json | jq -r --arg n "$name" '.[] | select(.Name==$n) | .Path' | head -1)
    ;;
esac

# Create the target session (detached) if it does not exist yet.
if ! tmux has-session -t "=$name" 2>/dev/null; then
  [ -z "${path:-}" ] && { tmux display-message "No session or path for: $name"; exit 0; }
  tmux new-session -d -s "$name" -c "$path"
fi

# Move the current window to the end of the target session.
tmux move-window -t "$name:"
tmux display-message "Moved window → $name"

[ "$key" = "ctrl-s" ] && tmux switch-client -t "$name:"
