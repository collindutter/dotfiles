# Rex

`init.lua` mirrors `~/.config/tmux/tmux.conf`. Reload with `rex config reload`
or `Ctrl+a r` / `Cmd+r`. Native macOS shortcuts remain available.

All keys below follow `Ctrl+a`:

| Key | Action |
| --- | --- |
| `Ctrl+a` | Send Ctrl+a to terminal |
| `c`, `|`, `\` | New tab, split right, split down, in current directory |
| `n`, `p`, `1`–`9` | Next, previous, numbered tab |
| `{`, `}` | Swap with previous, next pane in the layer, wrapping at ends |
| `,`, `$` | Rename tab, session |
| `x`, `&` | Close pane, tab |
| `m`, `z` | Zoom pane |
| Arrows | Resize by 5% of split; repeat prefix for each press |
| `h/j/k/l`, `o` | Focus direction, next pane |
| `s`, `O` | Native Rex session picker |
| `w`, `W` | Command palette, not tmux's window picker |
| `/` | Native Find, not reverse vi copy-mode search |
| `g` | Lazygit in a 90% floating layer; quit Lazygit to close |
| `D` | Workmux dashboard in a 90% floating layer |
| `A` | Aven tasks across all projects in a 90% floating layer |

Choose **Use Catppuccin Macchiato** in the command palette to apply the theme.
Client appearance settings live in Rex, not this Lua config:
JetBrainsMono Nerd Font Mono, 17 pt, font smoothing on, Display P3 on.

Ctrl+h/j/k/l works without a prefix and is shared with Neovim: Rex moves between panes for
other foreground programs, while a foreground Neovim receives the key. Neovim
moves through its own splits first and delegates an edge move back to Rex.
The prefix navigation above remains an escape hatch. Rex uses its own
scrollback limit (about 64 MiB).
