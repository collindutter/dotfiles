#!/bin/bash

# Install xCode cli tools
echo "Installing commandline tools..."
xcode-select --install

# Install Homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

echo "Installing Homebrew packages..."
brew install neovim
brew install jq
brew install ripgrep
brew install tmux
brew install fish
brew install yabai
brew install skhd
brew install starship

echo "Switching to fish shell..."
sudo echo /usr/local/bin/fish >> /etc/shells
chsh -s /usr/local/bin/fish

# Update macOS Settings
echo "Changing macOS defaults..."
defaults write com.apple.dock autohide -bool true
defaults write com.apple.spaces spans-displays -bool false

defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain KeyRepeat -int 1

defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
defaults write com.apple.Finder AppleShowAllFiles -bool true

# Install asdf
echo "Installing asdf..."
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.12.0
echo source ~/.asdf/asdf.fish
echo mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions

echo "Installing asdf plugins..."
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

echo "Installing nodejs..."
asdf install nodejs latest
asdf global nodejs latest

echo "Installing python..."
asdf plugin add python
asdf global python latest

echo "Installing poetry..."
curl -sSL https://install.python-poetry.org | python3 -

echo "Installing tpm..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing Fisher..."
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

echo "Installing bass..."
fisher install bass

$ echo "Installing fish catpuccin..."
fisher install catppuccin/fish

echo "Starting Services..."
yabai --start-service
skhd --start-service

echo "Configuring poetry..."
poetry config virtualenvs.in-project true

echo "Configuring git..."
git config --global user.name "Collin Dutter"
git config --global user.email "collindutter@gmail.com"

echo "Configuring dotfiles..."
alias --save dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
echo ".dotfiles" >> .gitignore
git clone --bare https://github.com/collindutter $HOME/.dotfiles
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
