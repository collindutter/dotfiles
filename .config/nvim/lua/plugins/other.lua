return {
  'rgroli/other.nvim',
  main="other-nvim",
  opts = {
    mappings = {
      'python',
    },
  },
  init = function()
    local map = require('helpers.keys').map

    map('n', '<leader>o', "<cmd>Other<cr>", '[o]ther')
  end,
}
