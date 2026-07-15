function brew-sync --wraps='brew update && brew bundle install --force-cleanup --file=~/.config/homebrew/Brewfile && brew upgrade' --description 'alias brew-sync brew update && brew bundle install --force-cleanup --file=~/.config/homebrew/Brewfile && brew upgrade'
  brew update && brew bundle install --force-cleanup --file=~/.config/homebrew/Brewfile && brew upgrade --yes $argv
end
