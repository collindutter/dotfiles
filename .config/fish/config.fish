fish_add_path /usr/local/sbin
fish_add_path /usr/local/opt/yq@3/bin
fish_add_path /usr/local/opt/openjdk@11/bin
fish_add_path /usr/local/opt/openjdk/bin
fish_add_path $HOME/.jenv/bin 

if status --is-interactive
	set -gx COLORTERM truecolor
	set -gx EDITOR nvim --clean
	set -gx VIRTUAL_ENV_DISABLE_PROMPT true
	set -gx HOMEBREW_AUTO_UPDATE_SECS 86400
	set -g fish_key_bindings fish_vi_key_bindings
	set -g fish_bind_mode insert
	set fish_greeting
	fish_config theme choose "Catppuccin Mocha"


# Title options
	set -g theme_title_display_process yes
	set -g theme_title_display_path yes
	set -g theme_title_display_user yes
	set -g theme_title_use_abbreviated_path yes

# Prompt options
	set -g theme_display_virtualenv yes
	set -g theme_display_vagrant no
	set -g theme_display_user yes
	set -g theme_display_hostname yes
	set -g theme_show_exit_status yes
	set -g theme_git_worktree_support no
	set -g theme_display_git yes
	set -g theme_display_git_dirty yes
	set -g theme_display_git_untracked yes
	set -g theme_display_git_ahead_verbose yes
	set -g theme_display_git_dirty_verbose yes
	set -g theme_display_git_master_branch yes
	set -g theme_display_date yes
	set -g theme_display_cmd_duration yes

	zoxide init fish | source
	thefuck --alias | source

  # nvm
	function nvm
   	 bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
	end
	set -x NVM_DIR ~/.nvm
	nvm use default --silent

  # pyenv
	if type -q pyenv
		pyenv init - | source
		. ~/.config/fish/functions/auto_source_venv.fish
	end

  # jenv
	if type -q jenv
		jenv init - | source
	end

	if not set -q TMUX
    set -g TMUX tmux new-session -d -s personal
    eval $TMUX
    tmux attach-session -d -t personal
	end
end

