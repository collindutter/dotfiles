# ANSI color names, so fzf follows the terminal's light or dark palette.
set -gx FZF_DEFAULT_OPTS \
    "--color=16,bg:-1,bg+:-1,fg:-1,fg+:-1:bold,selected-bg:-1" \
    "--color=hl:red,hl+:red:bold,info:magenta,prompt:magenta,header:red" \
    "--color=pointer:red,marker:blue,spinner:red,border:8,label:-1"
