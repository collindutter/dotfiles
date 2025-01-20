fish_add_path /usr/local/sbin
fish_add_path /usr/local/opt/yq@3/bin
fish_add_path /usr/local/opt/openjdk@11/bin
fish_add_path /usr/local/opt/openjdk/bin
fish_add_path ~/.local/bin
fish_add_path $HOME/.jenv/bin 
fish_add_path /opt/homebrew/bin
fish_add_path ~/.local/share/

if status --is-interactive
	fish_vi_key_bindings
	set -g fish_vi_force_cursor 1

	set fish_cursor_default block
	set fish_cursor_insert line
	set fish_cursor_replace_one underscore

	bind -M insert -m default jk backward-char force-repaint

	set fish_greeting
	fzf_configure_bindings --directory=\cf --git_log=\cl
	
	fish_config theme choose "Catppuccin Macchiato"
	
	zoxide init fish | source
	starship init fish | source
	mise activate fish | source
end
