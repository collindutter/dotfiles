-- Many of these were copied from mini.basics https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/basics.lua#L437

local o, opt = vim.o, vim.opt
local g = vim.g

g.python3_host_prog = vim.fn.expand '~/.virtualenvs/py3nvim/bin/python' -- set python provider

opt.shortmess:append 'WcC' -- Reduce command line messages

-- Basic UI Enhancements
o.number = true -- Show line numbers
o.relativenumber = true -- Show relative line numbers
o.showmatch = true -- Highlight matching brackets
o.foldmethod = 'syntax' -- Enable syntax-based folding
o.showcmd = false -- Don't show partial commands in the last line of the screen
o.pumheight = 10 -- Make popup menu smaller

-- Editing Improvements
o.expandtab = true -- Convert tabs to spaces
o.shiftwidth = 4 -- Spaces per step of (auto)indent
o.tabstop = 4 -- Spaces that a tab counts for
o.smartindent = true -- Smart indenting on new lines
o.autoindent = true -- Keep indent from previous line

-- Search & Navigation
o.incsearch = true -- Show partial matches for a search phrase
o.inccommand = 'split' -- Show live preview of :s commands
o.ignorecase = true -- Ignore case in search patterns
o.smartcase = true -- Override `ignorecase` for uppercase patterns
o.infercase = true -- Infer letter cases for a richer built-in keyword completion
o.grepprg = 'rg --vimgrep' -- Use Ripgrep for the :grep commanr
o.grepformat = '%f:%l:%c:%m' -- Format for parsing the grep output

-- File Handling
o.backup = false -- Disable making a backup before overwriting a file
o.swapfile = false -- Disable swap file creation
o.undofile = true -- Enable persistent undo
o.autowrite = true -- Auto-write buffer when it's not the current buffer
o.confirm = true -- Confirm to save changes before exiting modified buffer
o.fileformats = 'unix,dos,mac' -- Support all three line endings

-- Visual Tweaks
o.cursorline = true -- Highlight the current line
o.wrap = false -- Disable line wrapping
o.ruler = false -- Don't show cursor position in command line
o.scrolloff = 8 -- Start scrolling when 8 lines away from margins
o.sidescrolloff = 8 -- Same as `scrolloff`, but for horizontal scrolling
o.signcolumn = 'yes' -- Always show the sign column
o.showmode = false -- Hide the current mode indicator
o.laststatus = 3 -- Always show the status line

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Miscellaneous
o.mouse = 'a' -- Enable mouse support
-- https://github.com/nvim-lua/kickstart.nvim/pull/1049
vim.schedule(function()
  o.clipboard = 'unnamedplus' -- Use the system clipboard
end)
o.timeoutlen = 300 -- Time in milliseconds for a mapped sequence
o.termguicolors = true -- Enable 24-bit RGB colors

-- Completion options
o.completeopt = 'menuone,noinsert,noselect'

-- Split behavior
o.splitright = true -- Open vertical splits to the right
o.splitbelow = true -- Open horizontal splits below
o.splitkeep = 'screen' -- Reduce scroll during window split

o.winborder = 'rounded' -- Use rounded borders

opt.foldmethod = 'expr' -- Enable expression folding
opt.foldexpr = 'v:vim.lsp.foldexpr()' -- LSP folding expression
opt.foldlevel = 99 -- Don't autoclose folds

-- Make diagnostics pretty
vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '󰌵',
      [vim.diagnostic.severity.INFO] = '󰋼',
    },
  },
  severity_sort = true,
}
