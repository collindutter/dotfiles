function deps-sync --description 'Run brew-sync, mise up, and update nvim/tmux plugins'
    set -l failures

    brew-sync $argv
    or set -a failures brew-sync

    mise up
    or set -a failures 'mise up'

    nvim --headless '+Lazy! sync' +qa
    or set -a failures 'nvim lazy sync'

    ~/.tmux/plugins/tpm/bin/install_plugins
    or set -a failures 'tmux install_plugins'

    ~/.tmux/plugins/tpm/bin/update_plugins all
    or set -a failures 'tmux update_plugins'

    deps-sync-commit
    or set -a failures deps-sync-commit

    if test (count $failures) -gt 0
        echo '' >&2
        echo 'deps-sync: some steps failed:' >&2
        for step in $failures
            echo "  - $step" >&2
        end
        return 1
    end
end

function deps-sync-commit
    set -l dep_files nvim/lazy-lock.json mise/config.toml homebrew/Brewfile
    set -l changed
    for file in $dep_files
        if not dotfiles diff --quiet -- ~/.config/$file
            set -a changed ~/.config/$file
        end
    end
    if test (count $changed) -eq 0
        echo 'deps-sync: no dependency changes to commit'
        return 0
    end
    dotfiles add $changed
    and dotfiles commit -m 'chore(deps): sync dependencies' -- $changed
end
