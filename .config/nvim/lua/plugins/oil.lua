return {
  -- File explorer as buffer
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    keymaps = {
      ['<C-l>'] = false,
      ['<C-h>'] = false,
      ['q'] = 'actions.close',
      ['H'] = 'actions.toggle_hidden',
    },
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '-', '<cmd>Oil<cr>', 'Open Oil')
  end,
}
