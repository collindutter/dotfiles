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
          -- width = 0,
        },
      },
      diff = {
        provider = 'mini_diff',
      },
    },
  },
  keys = {
    { '<leader>au', '<cmd>CodeCompanionChat Toggle<cr>', desc = '[a]I [u]I' },
    { '<leader>au', '<cmd>CodeCompanionChat Toggle<cr>', mode = 'v', desc = '[a]I [u]I' },
    { 'ga', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = '[g]lobal [a]dd to UI' },
  },
}
