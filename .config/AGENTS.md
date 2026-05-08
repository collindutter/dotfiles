# Dotfiles repo guide

This home directory is the work tree for a bare Git dotfiles repository. The Git database lives at `~/.dotfiles`, and tracked files are checked out directly under `$HOME`.

## Use the dotfiles Git context

Use the fish helper when it is available:

```bash
dotfiles status --short
dotfiles diff -- path/to/file
dotfiles add path/to/file
dotfiles commit -m "type(scope): message"
dotfiles pull --rebase
dotfiles push
```

The helper is defined in `~/.config/fish/functions/dotfiles.fish` as:

```bash
/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME
```

Do not `cd ~/.dotfiles` to edit files. That directory is Git metadata only. Edit files in `$HOME`, then stage them with `dotfiles add`.

## Working with tracked files

Untracked files are hidden by default because the repo has `status.showUntrackedFiles = no`. New files will not appear in normal status output until they are explicitly added.

Useful commands:

```bash
dotfiles ls-files
dotfiles ls-files --others --exclude-standard path/to/file
dotfiles check-ignore -v path/to/file
dotfiles status --short
dotfiles diff
dotfiles diff --cached
```
