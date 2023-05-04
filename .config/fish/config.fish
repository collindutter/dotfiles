fish_add_path /usr/local/sbin
fish_add_path /usr/local/opt/yq@3/bin
fish_add_path /usr/local/opt/openjdk@11/bin
fish_add_path /usr/local/opt/openjdk/bin
fish_add_path $HOME/.jenv/bin 

if status --is-interactive
	set fish_key_bindings fish_user_key_bindings
	set fish_greeting
	fish_config theme choose "Catppuccin Mocha"

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
end

