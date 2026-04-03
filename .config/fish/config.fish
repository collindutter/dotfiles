fish_add_path ~/.local/bin
fish_add_path /opt/homebrew/bin
fish_add_path ~/.local/share/

if status --is-interactive
	# https://fishshell.com/docs/current/interactive.html#vi-mode-commands
	# Enable vi key bindings
	fish_vi_key_bindings

	# Have the cursor change shape in different modes
	fish_vi_cursor

	# Leave insert mode when pressing jk
	bind -M insert -m default jk backward-char force-repaint

	# Disable the default fish greeting
	set fish_greeting
	
	# Improve fzf key bindings
	fzf_configure_bindings --directory=\cf
	
	fish_config theme choose "catppuccin-macchiato"
	
	zoxide init fish | source
	starship init fish | source
	mise activate fish | source
end
