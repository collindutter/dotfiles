# Rex

Reload `init.lua` with `rex config reload` or `Ctrl+a r`. Native macOS
shortcuts remain available.

All keys below follow `Ctrl+a`:

| Key | Action |
| --- | --- |
| `Ctrl+a` | Send Ctrl+a to terminal |
| `c` | New tab |
| `\|`, `\` | Split right, split down |
| `n`, `p`, `1`–`9` | Next, previous, numbered tab |
| `{`, `}` | Swap pane with previous, next in layout order, wrapping (tmux `swap-pane`) |
| `,`, `$` | Rename tab, session |
| `x`, `&` | Close pane, tab; `&` on a worktree's tab offers to remove the worktree |
| `m` | Zoom pane |
| `h/j/k/l`, `o` | Focus direction, next pane |
| `s`, `O` | Session picker; opens the session on its first tab (Cmd+K keeps the last tab) |
| `/` | Find |
| `[` | Copy mode |
| `u` | URLs in the pane, in a floating layer |
| `g` | Lazygit in a 90% floating layer; quit Lazygit to close |
| `w` | Worktree picker: switch to a worktree or branch, or create one |
| `A` | Aven tasks across all projects in a 90% floating layer |

`themes/` holds the official Catppuccin Ghostty themes. Rex follows the system
appearance, with Latte for light and Macchiato for dark. To restore them, run
**Import Theme File** on each file, then set Settings > Appearance back to System.
Client appearance settings live in Rex, not this Lua config:
JetBrainsMono Nerd Font Mono, 17 pt, font smoothing on, Display P3 on.

Ctrl+h/j/k/l works without a prefix and is shared with Neovim: Rex moves between panes for
other foreground programs, while a foreground Neovim receives the key. Neovim
moves through its own splits first and delegates an edge move back to Rex.
The prefix navigation above remains an escape hatch. Rex uses its own
scrollback limit (about 64 MiB).

## Worktrees

[workmux](https://workmux.dev/guide/rex/) gives each worktree its own window in
the current session, with the Neovim and Pi layout from
`~/.config/workmux/config.yaml`. `workmux add`, `open` and `remove` work from
any Rex terminal. The `w` and `&` bindings in `worktrees.lua` run workmux and
show the window themselves, so they don't need Remote Control. Switching
windows from the CLI does.
