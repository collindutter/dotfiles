-- Set leader
local leader_key = ' '
vim.g.mapleader = leader_key
vim.g.maplocalleader = leader_key
vim.keymap.set({ 'n', 'v' }, leader_key, '<nop>')

-- Remap for dealing with word wrap
vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Center buffer after moving up or down
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Center cursor after moving down half-page' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Center cursor after moving up half-page' })

-- Splits
vim.keymap.set('n', '|', function()
  vim.cmd.vsplit()
end, { desc = 'Vertical split' })
vim.keymap.set('n', '\\', function()
  vim.cmd.split()
end, { desc = 'Horizontal split' })

-- Quit all
vim.keymap.set('n', '<leader>qq', '<cmd>qa!<cr>', { desc = '[qq]uit all' })

-- Files
vim.keymap.set('n', '<leader>n', function()
  vim.cmd.enew()
end, { desc = '[n]ew file' })
vim.keymap.set('n', '<leader>w', function()
  pcall(vim.cmd.w)
end, { desc = 'Save file' })

-- Paste without yanking
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without yanking' })

-- Ese `gp` to visually select the last paste
vim.keymap.set('n', 'gp', function()
  return '`[' .. string.sub(vim.fn.getregtype(), 1, 1) .. '`]'
end, { noremap = true, expr = true })

-- Adds numbered jk (10j, 15k) movement to jumplist
vim.keymap.set({ 'n', 'x' }, 'j', function()
  return vim.v.count > 1 and "m'" .. vim.v.count .. 'j' or 'j'
end, { noremap = true, expr = true })
vim.keymap.set({ 'n', 'x' }, 'k', function()
  return vim.v.count > 1 and "m'" .. vim.v.count .. 'k' or 'k'
end, { noremap = true, expr = true })

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
