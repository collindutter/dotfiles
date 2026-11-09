#!/bin/sh
# fzf over programs that report a status, most urgent first. Enter jumps to the
# program's pane. Started by `ctrl+a W` in a floating layer.
dir=$(dirname "$0")
sel=$(rex do "$dir/status.lua" |
	jq -r '.[] | [.session_id, .window_id, .block_id, .state, .session, .tab, .msg] | @tsv' |
	awk -F'\t' '{ printf "%s\t%s\t%s\t%-8s  %-24s  %s  %s\n", $1, $2, $3, $4, $5, $6, $7 }' |
	fzf --delimiter='\t' --with-nth=4 --no-sort --reverse --prompt='activity> ') || exit 0
IFS="$(printf '\t')" read -r session_id window_id block_id _ <<EOT
$sel
EOT
exec rex do "$dir/go.lua" session_id="$session_id" window_id="$window_id" block_id="$block_id"
