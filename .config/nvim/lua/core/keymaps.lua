local map = require('helpers.keys').map

map({ 'n', 'v' }, '<Space>', '<Nop>', 'Ensure space is clear for leader')

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Center buffer after moving up or down
map('n', '<C-d>', '<C-d>zz', 'Center cursor after moving down half-page')
map('n', '<C-u>', '<C-u>zz', 'Center cursor after moving up half-page')

-- Tab movement
map('n', ']t', function()
  vim.cmd.tabnext()
end, 'Next [t]ab')
map('n', '[t', function()
  vim.cmd.tabprevious()
end, 'Previous [t]ab')

-- Quickfix list movement
map('n', ']q', function()
  vim.cmd.cn()
end, 'Next [q]uickfix item')
map('n', '[q', function()
  vim.cmd.cp()
end, 'Previous [q]uickfix item')

map('n', '|', function()
  vim.cmd.vsplit()
end, 'Vertical split')
map('n', '\\', function()
  vim.cmd.split()
end, 'Horizontal split')

map('n', '<leader>w', function()
  vim.fn.histadd('cmd', 'w') -- HACK: https://github.com/stevearc/oil.nvim/issues/221
  pcall(vim.cmd.w)
end, 'Save file')
map('n', '<leader>q', '<cmd>confirm q<cr>', 'Confirm [q]uit')
map('n', '<leader>Q', '<cmd>qa!<cr>', '[Q]uit all')
map('n', '<leader>n', function()
  vim.cmd.enew()
end, '[n]ew file')

map('n', '<leader>cj', function()
  vim.cmd '%!jq .'
end, '[c]ode format [j]SON')

map('n', '<leader>lr', function()
  vim.cmd 'LspRestart'
end, '[l]SP [r]estart')
