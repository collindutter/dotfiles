# Dotfiles

This repo is a bare git repository at `$HOME/.dotfiles/` with `$HOME` as the work tree. All git commands must use:

```
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME <command>
```

The `dotfiles` fish function is a convenience alias for this.