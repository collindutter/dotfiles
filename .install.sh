#!/bin/bash

echo "Installing commandline tools..."
xcode-select --install

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew analytics off

echo "Installing Homebrew packages..."
brew update
brew bundle install --cleanup --file=~/.config/homebrew/Brewfile --no-lock
brew upgrade

echo "Switching to fish shell..."
sudo echo /usr/local/bin/fish >>/etc/shells
chsh -s /usr/local/bin/fish

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

echo "Installing tpm..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing Fisher..."
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

echo "Installing Fisher packages..."
fisher install PatrickF1/fzf.fish
fisher install catppuccin/fish

echo "Configuring dotfiles..."
alias --save dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
echo ".dotfiles" >>.gitignore
git clone --bare https://github.com/collindutter $HOME/.dotfiles
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no

echo "Configuring neovim virtualenvs..."
mkdir .virtualenvs
python -m venv .virtualenvs/py3nvim
./virtualenvs/bin/pip install pynvim
python -m venv .virtualenvs/debugpy
./virtualenvs/bin/pip install debugpy
