fish_add_path /usr/local/sbin
fish_add_path /usr/local/opt/yq@3/bin
fish_add_path /usr/local/opt/openjdk@11/bin
fish_add_path /usr/local/opt/openjdk/bin
fish_add_path ~/.local/bin
fish_add_path $HOME/.jenv/bin 
fish_add_path /opt/homebrew/bin
fish_add_path ~/.local/share/

if status --is-interactive

	# https://fishshell.com/docs/current/interactive.html#vi-mode-commands
	# Enable vim mode
	fish_vi_key_bindings
	# Have the cursor change shape in different modes
	fish_vi_cursor
	# All required to make this work in tmux
	set -g fish_vi_force_cursor 1
	set fish_cursor_default block
	set fish_cursor_insert line
	set fish_cursor_replace_one underscore
	set fish_cursor_replace underscore
	set fish_cursor_external line
	set fish_cursor_visual block

	# Leave insert mode when pressing jk
	bind -M insert -m default jk backward-char force-repaint

	# Disable the default fish greeting
	set fish_greeting
	
	# Improve fzf key bindings
	fzf_configure_bindings --directory=\cf
	
	fish_config theme choose "Catppuccin Macchiato"
	
	zoxide init fish | source
	starship init fish | source
	mise activate fish | source
end
