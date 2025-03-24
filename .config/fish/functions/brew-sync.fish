function brew-sync --wraps='brew update && brew bundle install --cleanup --file=~/.config/homebrew/Brewfile && brew upgrade' --description 'alias brew-sync brew update && brew bundle install --cleanup --file=~/.config/homebrew/Brewfile --no-lock && brew upgrade'
  brew update && brew bundle install --cleanup --file=~/.config/homebrew/Brewfile && brew upgrade $argv
end
