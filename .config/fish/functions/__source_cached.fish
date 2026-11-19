# Sources a command's output, regenerating it only when the command or the
# file it depends on changes.
function __source_cached --argument-names name dep
    set -l cmd $argv[3..]
    set -l cache $__fish_cache_dir/$name.fish
    set -l key "# $(path resolve -- $dep) $(path mtime -- $dep) $cmd"
    set -l line
    test -r $cache; and read -l line <$cache
    if test "$line" != "$key"
        mkdir -p $__fish_cache_dir
        begin
            echo $key
            $cmd
        end >$cache
    end
    source $cache
end
