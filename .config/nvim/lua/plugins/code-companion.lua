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
    { '<leader>ua', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = '[u]I [a]I' },
    { 'ga', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = '[g]lobal [a]dd to UI' },
  },
}
