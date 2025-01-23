return {
  'MagicDuck/grug-far.nvim',
  keys = {
    {
      '<leader>sr',
      function()
        require('grug-far').open()
      end,
      desc = '[s]hange [r]eplace',
    },
  },
  opts = {
    keymaps = {
      qflist = { n = '<C-q>' },
      close = false,
    },
  },
}
