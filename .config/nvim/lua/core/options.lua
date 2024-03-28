vim.opt.shortmess:append 'I' -- Disable intro message
local options = {
  g = {
    python3_host_prog = '~/.virtualenvs/py3nvim/bin/python', -- set python provider
  },
  opt = {
    -- Basic UI Enhancements
    number = true, -- Show line numbers
    relativenumber = true, -- Show relative line numbers
    showmatch = true, -- Highlight matching brackets
    foldmethod = 'syntax', -- Enable syntax-based folding
    showcmd = false,

    -- Editing Improvements
    expandtab = true, -- Convert tabs to spaces
    shiftwidth = 4, -- Spaces per step of (auto)indent
    tabstop = 4, -- Spaces that a tab counts for
    smartindent = true, -- Smart indenting on new lines
    autoindent = true, -- Keep indent from previous line

    -- Search & Navigation
    hlsearch = true, -- Highlight all search results
    incsearch = true, -- Show partial matches for a search phrase
    inccommand = 'split', -- Show live preview of :s commands
    ignorecase = true, -- Ignore case in search patterns
    smartcase = true, -- Override `ignorecase` for uppercase patterns
    grepprg = 'rg --vimgrep', -- Use Ripgrep for the :grep commanr
    grepformat = '%f:%l:%c:%m', -- Format for parsing the grep output

    -- File Handling
    backup = false, -- Disable making a backup before overwriting a file
    swapfile = false, -- Disable swap file creation
    undofile = true, -- Enable persistent undo
    autowrite = true, -- Auto-write buffer when it's not the current buffer
    confirm = true, -- Confirm to save changes before exiting modified buffer
    wildmenu = false, -- Disable command-line completion menu (we're using cmp)

    -- Visual Tweaks
    cursorline = true, -- Highlight the current line
    wrap = false, -- Disable line wrapping
    scrolloff = 8, -- Start scrolling when 8 lines away from margins
    sidescrolloff = 8, -- Same as `scrolloff`, but for horizontal scrolling
    signcolumn = 'yes', -- Always show the sign column
    showmode = false, -- Hide the current mode indicator
    laststatus = 3, -- Always show the status line
    list = true, -- Sets how neovim will display certain whitespace characters in the editor
    listchars = { tab = '» ', trail = '·', nbsp = '␣' }, -- Set the characters

    -- Miscellaneous
    mouse = 'a', -- Enable mouse support
    clipboard = 'unnamedplus', -- Use the system clipboard
    timeoutlen = 300, -- Time in milliseconds for a mapped sequence
    termguicolors = true, -- Enable 24-bit RGB colors

    -- Completion options
    completeopt = { 'menuone', 'noselect' },

    -- Split behavior
    splitright = true, -- Open vertical splits to the right
    splitbelow = true, -- Open horizontal splits below
  },
}

for scope, table in pairs(options) do
  for setting, value in pairs(table) do
    vim[scope][setting] = value
  end
end
