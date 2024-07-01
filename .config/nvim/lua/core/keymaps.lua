local map = require('helpers.keys').map

-- Set leader
local leader_key = ' '
vim.g.mapleader = leader_key
vim.g.maplocalleader = leader_key
vim.keymap.set({ 'n', 'v' }, leader_key, '<nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Center buffer after moving up or down
map('n', '<C-d>', '<C-d>zz', 'Center cursor after moving down half-page')
map('n', '<C-u>', '<C-u>zz', 'Center cursor after moving up half-page')

-- Splits
map('n', '|', function()
  vim.cmd.vsplit()
end, 'Vertical split')
map('n', '\\', function()
  vim.cmd.split()
end, 'Horizontal split')

-- Quit and force quit
map('n', '<leader>q', '<cmd>confirm q<cr>', 'Confirm [q]uit')
map('n', '<leader>Q', '<cmd>qa!<cr>', '[Q]uit all')

-- Files
map('n', '<leader>n', function()
  vim.cmd.enew()
end, '[n]ew file')

map('n', '<leader>w', function()
  vim.cmd.w()
end, 'Save file')
