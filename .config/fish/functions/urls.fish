function urls --description 'Pick URLs from stdin with fzf, then open or copy them'
    if test -t 0
        echo 'usage: <command> | urls' >&2
        return 1
    end

    # In a fish pipeline, a function's stdin doesn't reach command
    # substitutions, so read it with a builtin first.
    read -z input

    # Reverse the lines so the newest URLs come first and survive dedupe.
    # --expect puts the pressed key on the first line (empty for enter),
    # followed by the selected URLs.
    set -l out (printf %s $input | tail -r | $__fish_config_dir/extract-urls.pl \
        | fzf --multi --no-sort --wrap --layout reverse --expect ctrl-y \
        --header 'Enter: Open URL / CTRL-Y: Copy to clipboard')
    or return

    set -l key $out[1]
    set -l chosen $out[2..]
    test -n "$chosen"; or return

    if test "$key" = ctrl-y
        string join \n $chosen | string collect | pbcopy
    else
        open $chosen
    end
end
