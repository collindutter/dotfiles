fish_add_path -gP ~/.local/bin /opt/homebrew/bin /opt/homebrew/sbin ~/.local/share

set -gx XDG_CONFIG_HOME $HOME/.config

# Let self-updating casks (Chrome, etc.) manage their own versions
set -gx HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS 1

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

	# Shorthand for workmux
	abbr -a wm workmux
	
	# Improve fzf key bindings
	fzf_configure_bindings --directory=\cf
	
	fish_config theme choose "catppuccin-macchiato"
	
	zoxide init fish | source
	starship init fish | source
	mise activate fish | source
end
