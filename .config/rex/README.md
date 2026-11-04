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
| `{`, `}` | Move pane left, right |
| `,`, `$` | Rename tab, session |
| `x`, `&` | Close pane, tab |
| `m` | Zoom pane |
| Arrows | Resize by 5% of split and enter resize mode; arrows keep resizing until Escape or Enter |
| `h/j/k/l`, `o` | Focus direction, next pane |
| `s` | Session picker |
| `/` | Find |
| `g` | Lazygit in a 90% floating layer; quit Lazygit to close |
| `O` | Session picker in the style of sesh: opens on sessions, `^a` adds zoxide directories; Enter connects or opens a session, `^y` copies the path |
| `W` | Activity picker: programs that report a status, most urgent first; Enter jumps to the pane |
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

[rex-worktrunk](https://github.com/haxybaxy/rex-worktrunk) gives each
[worktrunk](https://worktrunk.dev) worktree its own window in the current
session, with Neovim and Pi side by side. `wt switch -c <branch>` and `wt remove`
from the CLI open and close windows through the hooks in
`~/.config/worktrunk/config.toml`. The local copy adds the `target` and `prefix`
options for this. Its fzf picker is unused; `wt switch` has its own.

## Pickers

`pickers/` holds the fzf pickers on `O` and `W`. `status.lua` and `sessions.lua`
list programs and sessions, and `go.lua` shows a session in the app.
Directories open as sessions through rex-worktrunk's `worktree_go`, so they get
the Neovim and Pi layout.
