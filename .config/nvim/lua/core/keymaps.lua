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

map('n', '|', '<cmd>vsplit<cr>', 'Vertical split')
map('n', '\\', '<cmd>split<cr>', 'Horizontal split')

map('n', '<leader>q', '<cmd>confirm q<cr>', 'Confirm quit')
map('n', '<leader>w', '<cmd>confirm q<cr>', 'Save buffer')
map('n', '<leader>n', '<cmd>enew<cr>', 'New buffer')
