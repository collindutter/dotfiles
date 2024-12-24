return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    display = {
      chat = {
        window = {
          layout = 'vertical',
          width = 0,
        },
      },
      diff = {
        provider = 'mini_diff',
      },
    },
  },
  init = function()
    local map = require('helpers.keys').map
    map('n', '<leader>au', '<cmd>CodeCompanionChat Toggle<cr>', '[a]I [u]I')
    map('v', '<leader>au', '<cmd>CodeCompanionChat Toggle<cr>', '[a]I [u]I')
    map('v', 'ga', '<cmd>CodeCompanionChat Add<cr>', '[g]lobal [a]dd to UI')
  end,
}
