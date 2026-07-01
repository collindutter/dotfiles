#!/usr/bin/env bash
# Sesh session picker with two actions:
#   Enter   connect to the selected session
#   C-y     copy the selected session's path to the clipboard

set -euo pipefail

result=$(
  sesh list --icons -H | fzf \
    --ansi --tiebreak=length,begin,index \
    --header '  ^a all  ^t tmux  ^g configs  ^x zoxide  ^f find    ^y copy path' \
    --expect=ctrl-y \
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

case "$key" in
  ctrl-y)
    # Strip any ANSI color codes that survive fzf --ansi output.
    clean=$(printf '%s' "$selection" | sed -E $'s/\x1b\\[[0-9;]*m//g')
    case "$clean" in
      /*)
        # Find-mode entries are bare absolute paths.
        path=$clean
        ;;
      *)
        # Sesh-mode entries are "<icon> <name>". Strip the icon glyph and
        # whitespace, then look the name up in the sesh JSON to get the path.
        name=$(printf '%s' "$clean" | sed -E 's/^[^[:space:]]+[[:space:]]+//')
        path=$(sesh list -H --json | jq -r --arg n "$name" '.[] | select(.Name==$n) | .Path' | head -1)
        [ -z "$path" ] && path=$clean
        ;;
    esac
    printf '%s' "$path" | pbcopy
    tmux display-message "Copied path: $path"
    ;;
  *)
    sesh connect "$selection"
    ;;
esac
