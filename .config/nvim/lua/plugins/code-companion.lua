return {

  'olimorris/codecompanion.nvim',

  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },

  opts = {
    adapters = {
      acp = {
        claude_code = function()
          return require('codecompanion.adapters').extend('claude_code', {})
        end,
      },
    },
    strategies = {
      chat = {
        adapter = 'claude_code',
      },
    },
    display = {
      chat = {
        window = {
          layout = 'vertical',
        },
      },
    },
  },
  keys = {
    { '<leader>ua', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = '[u]I [a]I' },
    { 'ga', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = '[g]lobal [a]dd to UI' },
  },
}
