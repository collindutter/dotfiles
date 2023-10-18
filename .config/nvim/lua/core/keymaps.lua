local map = require('helpers.keys').map

map({ 'n', 'v' }, '<Space>', '<Nop>', "Ensure space is clear for leader")

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Center buffer after moving up or down
map('n', '<C-d>', '<C-d>zz', 'Center cursor after moving down half-page')
map('n', '<C-u>', '<C-u>zz', 'Center cursor after moving up half-page')

-- Tab movement
map('n', ']t', function()
  vim.cmd.tabnext()
end, 'Next tab')
map('n', '[t', function()
  vim.cmd.tabprevious()
end, 'Previous tab')

-- Quickfix list movement
map('n', ']q', function() vim.cmd.cn() end, "Next quickfix item")
map('n', '[q', function() vim.cmd.cp() end, "Previous quickfix item")

map('n', '|', function() vim.cmd.vsplit() end, 'Vertical split')
map('n', '\\', function() vim.cmd.split() end, 'Horizontal split')

map('n', '<leader>q', '<cmd>confirm q<cr>', 'Confirm quit')
map('n', '<leader>fn', function() vim.cmd.enew() end, 'File new')

